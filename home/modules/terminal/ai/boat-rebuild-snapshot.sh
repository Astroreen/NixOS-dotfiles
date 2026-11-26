#!/usr/bin/env bash
# Build or refresh a secret-free boat.dev saved snapshot (default: dev-base)
# containing Antigravity CLI (`agy`), OpenCode v2, T3 Code, Claude Code, Codex,
# Tailscale, JDK 21, code-graph MCP servers, and the host's rendered AI payload
# (prompts, skills, commands, agents) for all four harnesses.
#
# Security: the builder sandbox is ALWAYS created with `--no-env`, so no Boat
# environment secrets, keys, tokens, or GitHub credentials ever land on disk.
set -euo pipefail

SNAPSHOT_NAME="${BOAT_DEFAULT_SNAPSHOT:-dev-base}"
FROM_SCRATCH=0
MACHINE_TYPE="default"

usage() {
  cat <<'EOF'
Usage: boat-rebuild-snapshot [OPTIONS] [SNAPSHOT_NAME]

Options:
  --from-scratch   Start from the stock Boat image instead of updating the existing snapshot
  --type <TYPE>    Builder machine size: small, default, large (default: default)
  -h, --help       Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --from-scratch) FROM_SCRATCH=1; shift ;;
    --type) MACHINE_TYPE="${2:?--type requires a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) SNAPSHOT_NAME="$1"; shift ;;
  esac
done

: "${AGY_VERSION:?AGY_VERSION must be set}"
: "${AGY_URL:?AGY_URL must be set}"
: "${AGY_SHA256_SRI:?AGY_SHA256_SRI must be set}"
: "${OPENCODE_VERSION:?OPENCODE_VERSION must be set}"
: "${OPENCODE_URL:?OPENCODE_URL must be set}"
: "${OPENCODE_SHA256_HEX:?OPENCODE_SHA256_HEX must be set}"
: "${CBM_VERSION:=v0.12.1}"
: "${GRAPHIFY_VERSION:=0.9.119}"
: "${T3_VERSION:=}"

log() { printf '[boat-rebuild-snapshot] %s\n' "$*"; }

# 1. Pack local rendered AI payload (dereferencing Nix store symlinks; zero secrets).
tmp_dir=$(mktemp -d)
sid=""
cleanup() {
  local rc=$?
  rm -rf "$tmp_dir"
  if [ -n "$sid" ]; then
    log "Deleting temporary builder sandbox $sid..."
    boat delete "$sid" --yes >/dev/null 2>&1 || true
  fi
  exit "$rc"
}
trap cleanup EXIT

payload_paths=()
for rel in \
  .claude/CLAUDE.md \
  .claude/skills \
  .claude/commands \
  .claude/agents \
  .codex/AGENTS.md \
  .codex/skills \
  .codex/agents \
  .agents/skills \
  .gemini/GEMINI.md \
  .gemini/config/skills \
  .gemini/config/agents \
  .config/opencode/AGENTS.md \
  .config/opencode/skills \
  .config/opencode/commands \
  .config/opencode/agents; do
  if [ -e "$HOME/$rel" ]; then
    payload_paths+=("$rel")
  fi
done

payload_tar="$tmp_dir/ai-payload.tar.gz"
if [ "${#payload_paths[@]}" -gt 0 ]; then
  log "Packing ${#payload_paths[@]} AI payload paths from $HOME..."
  tar -czhf "$payload_tar" \
    --exclude='.claude/skills/synced' \
    --exclude='.nix-managed-*' \
    -C "$HOME" \
    "${payload_paths[@]}"
  log "Payload archive size: $(du -h "$payload_tar" | cut -f1)"
else
  log "Warning: no local AI payload paths found under $HOME; creating empty archive."
  tar -czf "$payload_tar" --files-from /dev/null
fi

# 2. Ensure a clean, secret-free builder environment (`snapshot-builder`) exists.
#    Do NOT use `--no-env`: Boat permanently taints snapshots saved from a
#    `--no-env` sandbox so future sandboxes created with `--from` can never
#    attach `base` secrets or GitHub access. Instead, `snapshot-builder` has
#    safe-for-third-parties=false with every credential toggle disabled.
BUILDER_ENV="${BOAT_SNAPSHOT_BUILDER_ENV:-snapshot-builder}"
if ! boat env info "$BUILDER_ENV" >/dev/null 2>&1; then
  log "Creating clean Boat environment '$BUILDER_ENV' (zero secrets/credentials)..."
  boat env new "$BUILDER_ENV" >/dev/null
fi
boat env set "$BUILDER_ENV" \
  --safe-for-third-parties false \
  --github false \
  --secrets false \
  --boat-credentials false \
  --agents-credentials false >/dev/null

# 3. Check if the target saved snapshot already exists (for fast incremental rebuild).
new_args=(new --environment "$BUILDER_ENV" --ttl 2400 --type "$MACHINE_TYPE" --name "rebuild-${SNAPSHOT_NAME}" --json)
if [ "$FROM_SCRATCH" -eq 0 ]; then
  if boat snapshots --json 2>/dev/null | jq -es --arg n "$SNAPSHOT_NAME" '
      [ .[] | (.named // .savedSnapshots // .saved_snapshots // .snapshots // (if type == "array" then . else [.] end))[]? ]
      | any((type == "object") and (.name? == $n) and ((.status? // "ready") == "ready"))
    ' >/dev/null 2>&1; then
    log "Existing ready snapshot '$SNAPSHOT_NAME' found; performing incremental rebuild."
    new_args+=(--from "$SNAPSHOT_NAME")
  else
    log "No existing ready snapshot '$SNAPSHOT_NAME'; building from stock Boat image."
  fi
else
  log "--from-scratch set; building from stock Boat image."
fi

# 4. Create secret-free builder sandbox.
log "Creating secret-free builder sandbox (--environment $BUILDER_ENV)..."
create_out=$(boat "${new_args[@]}")
sid=$(printf '%s\n' "$create_out" | jq -rs '[ .[] | (.sandbox.id? // .id? // empty) ] | map(select(length > 0)) | last // empty')
if [ -z "$sid" ]; then
  echo "Failed to parse sandbox id from boat new output: $create_out" >&2
  exit 1
fi
log "Builder sandbox ready: $sid"

# 4. Upload payload archive (prefer boat scp, fall back to chunked base64 over boat exec).
log "Uploading AI payload archive to $sid:/tmp/ai-payload.tar.gz..."
if ! boat scp "$payload_tar" "$sid:/tmp/ai-payload.tar.gz" >/dev/null 2>&1; then
  log "boat scp unavailable; uploading via chunked base64 over boat exec..."
  boat exec "$sid" --timeout 60 -- "rm -f /tmp/ai-payload.tar.gz.b64 /tmp/ai-payload.tar.gz" >/dev/null
  b64_file="$tmp_dir/payload.b64"
  base64 -w 0 "$payload_tar" > "$b64_file"
  split -b 48000 "$b64_file" "$tmp_dir/chunk_"
  for chunk in "$tmp_dir"/chunk_*; do
    data=$(cat "$chunk")
    boat exec "$sid" --timeout 60 -- "printf '%s' '$data' >> /tmp/ai-payload.tar.gz.b64" >/dev/null
  done
  boat exec "$sid" --timeout 60 -- "base64 -d /tmp/ai-payload.tar.gz.b64 > /tmp/ai-payload.tar.gz && rm -f /tmp/ai-payload.tar.gz.b64" >/dev/null
fi

# 5. Provision tools + extract payload + audit zero secrets inside the builder sandbox.
provision_script="$tmp_dir/provision.sh"
cat > "$provision_script" <<'REMOTE_EOF'
#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/graphify-mcp"

if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
if ! grep -q '\.local/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
fi

log() { printf '[remote] %s\n' "$*"; }

# 1. Antigravity CLI (agy)
have_agy=$("$HOME/.local/bin/agy" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
if [ "$have_agy" != "$AGY_VERSION" ]; then
  log "Installing agy $AGY_VERSION..."
  tmp=$(mktemp -d)
  curl -fsSL "$AGY_URL" -o "$tmp/agy.tar.gz"
  python3 - "$tmp/agy.tar.gz" "$AGY_SHA256_SRI" <<'PY'
import base64, hashlib, sys
path, expected = sys.argv[1], sys.argv[2]
h = hashlib.sha256(open(path, "rb").read()).digest()
got = "sha256-" + base64.b64encode(h).decode("ascii")
if got != expected:
    raise SystemExit(f"agy sha256 mismatch: expected {expected}, got {got}")
PY
  tar -xzf "$tmp/agy.tar.gz" -C "$tmp"
  agy_bin=$(find "$tmp" -type f \( -name agy -o -name antigravity \) | head -n1)
  if [ -z "$agy_bin" ]; then
    echo "Could not find agy/antigravity binary in $tmp" >&2
    exit 1
  fi
  install -m 755 "$agy_bin" "$HOME/.local/bin/agy"
  rm -rf "$tmp"
else
  log "agy $AGY_VERSION already installed."
fi

# 2. OpenCode v2
have_oc=$("$HOME/.local/bin/opencode" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)
if [ "$have_oc" != "$OPENCODE_VERSION" ]; then
  log "Installing opencode v$OPENCODE_VERSION..."
  tmp=$(mktemp -d)
  curl -fsSL "$OPENCODE_URL" -o "$tmp/opencode.tar.gz"
  printf '%s  %s\n' "$OPENCODE_SHA256_HEX" "$tmp/opencode.tar.gz" | sha256sum -c -
  tar -xzf "$tmp/opencode.tar.gz" -C "$tmp"
  oc_bin=$(find "$tmp" -type f -name opencode | head -n1)
  install -m 755 "$oc_bin" "$HOME/.local/bin/opencode"
  rm -rf "$tmp"
else
  log "opencode v$OPENCODE_VERSION already installed."
fi

# 3. T3 Code server CLI (matching host version when pinned)
have_t3=$(t3 --version 2>/dev/null | sed -n 's/^t3 v//p' || true)
if [ -z "$have_t3" ] || { [ -n "$T3_VERSION" ] && [ "$have_t3" != "$T3_VERSION" ]; }; then
  log "Installing t3 ${T3_VERSION:-stable}..."
  curl -fsSL https://t3.codes/install.sh | T3CODE_VERSION="$T3_VERSION" T3CODE_INSTALL_BIN_DIR="$HOME/.local/bin" sh
else
  log "t3 $have_t3 already installed."
fi

# 4. Ensure Claude Code & Codex exist
if ! command -v claude >/dev/null 2>&1; then
  log "Installing @anthropic-ai/claude-code..."
  npm install -g --prefix "$HOME/.local" --no-fund --no-audit @anthropic-ai/claude-code >/dev/null
fi
if ! command -v codex >/dev/null 2>&1; then
  log "Installing @openai/codex..."
  npm install -g --prefix "$HOME/.local" --no-fund --no-audit @openai/codex >/dev/null
fi

# 5. Tailscale (installed only; never authenticated in snapshot)
if ! command -v tailscale >/dev/null 2>&1; then
  log "Installing tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl stop tailscaled >/dev/null 2>&1 || true
sudo rm -rf /var/lib/tailscale/tailscaled.state

# 6. JDK 21 (required by Caspian-Logistics-ERP backend/build.gradle)
if ! java -version 2>&1 | grep -q '"21\.'; then
  log "Installing openjdk-21-jdk-headless..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq openjdk-21-jdk-headless
  jdk21=$(dirname "$(dirname "$(readlink -f /usr/lib/jvm/java-21-openjdk-*/bin/java)")")
  if ! grep -q '^JAVA_HOME=' /etc/environment 2>/dev/null; then
    echo "JAVA_HOME=$jdk21" | sudo tee -a /etc/environment >/dev/null
  fi
  if ! grep -q 'JAVA_HOME=' "$HOME/.bashrc" 2>/dev/null; then
    echo "export JAVA_HOME=$jdk21" >> "$HOME/.bashrc"
  fi
else
  log "JDK 21 already installed."
fi

# 7. Code graphs: codebase-memory-mcp + graphify-mcp
have_cbm=$("$HOME/.local/bin/codebase-memory-mcp" --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)
want_cbm="${CBM_VERSION#v}"
if [ "${have_cbm#v}" != "$want_cbm" ]; then
  log "Installing codebase-memory-mcp $CBM_VERSION..."
  tmp=$(mktemp -d)
  asset="codebase-memory-mcp-linux-amd64-portable.tar.gz"
  base="https://github.com/DeusData/codebase-memory-mcp/releases/download/${CBM_VERSION}"
  curl -fsSL "$base/$asset" -o "$tmp/$asset"
  curl -fsSL "$base/checksums.txt" -o "$tmp/checksums.txt"
  (cd "$tmp" && grep " $asset\$" checksums.txt | sha256sum -c -)
  tar -xzf "$tmp/$asset" -C "$tmp"
  install -m 755 "$tmp/codebase-memory-mcp" "$HOME/.local/bin/codebase-memory-mcp"
  rm -rf "$tmp"
else
  log "codebase-memory-mcp $CBM_VERSION already installed."
fi

if [ ! -x "$HOME/.local/bin/graphify-mcp" ] || [ ! -x "$HOME/.local/share/graphify-mcp/run.sh" ]; then
  log "Installing graphifyy[mcp,sql]==$GRAPHIFY_VERSION..."
  uv tool install --upgrade "graphifyy[mcp,sql]==${GRAPHIFY_VERSION}"
  cat > "$HOME/.local/share/graphify-mcp/run.sh" <<'GRAPHIFY_RUN'
#!/usr/bin/env bash
set -euo pipefail
cache_home="${XDG_CACHE_HOME:-}"
[[ "$cache_home" == /* ]] || cache_home="$HOME/.cache"
cache_root="$cache_home/graphify-projects"
cache_root_real=""
if [[ ! -L "$cache_home" && ! -L "$cache_root" && -d "$cache_root" && -O "$cache_root" ]]; then
  cache_root_real="$(cd "$cache_root" && pwd -P)"
fi
main_key=""
wt_key=""
common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [[ -n "$common_dir" && -d "$common_dir" ]]; then
  common_real="$(cd "$common_dir" && pwd -P)"
  main_root_real="$(dirname "$common_real")"
  repo_name="$(basename "$main_root_real")"
  main_hash="$(printf '%s' "$common_real" | sha256sum | cut -c1-12)"
  main_key="${repo_name}-${main_hash}"
  top_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$top_dir" && -d "$top_dir" ]]; then
    top_real="$(cd "$top_dir" && pwd -P)"
    wt_hash="$(printf '%s' "$top_real" | sha256sum | cut -c1-12)"
    wt_key="${repo_name}-wt-${wt_hash}"
  fi
fi
pick_cached_graph() {
  local key="$1"
  [[ -n "$key" && -n "$cache_root_real" ]] || return 1
  local cand="$cache_root/$key/graphify-out/graph.json"
  [[ -f "$cand" && ! -L "$cand" ]] || return 1
  graph_path="$(cd "$(dirname "$cand")" && pwd -P)/graph.json"
}
graph_path=""
pick_cached_graph "$wt_key" || pick_cached_graph "$main_key" || true
if [[ -z "$graph_path" ]]; then
  echo "graphify-mcp: graph.json not found in $cache_root. Run scripts/mcp/refresh-graphs.sh first." >&2
  exit 1
fi
export GRAPHIFY_OUT="$(dirname "$graph_path")"
bin="$(command -v graphify-mcp 2>/dev/null || true)"
if [[ -z "$bin" ]] && command -v uv >/dev/null 2>&1; then
  cand="$(uv tool dir --bin)/graphify-mcp"
  [[ -x "$cand" ]] && bin="$cand"
fi
exec "${bin:-$HOME/.local/bin/graphify-mcp}" --graph "$graph_path" "$@"
GRAPHIFY_RUN
  chmod 755 "$HOME/.local/share/graphify-mcp/run.sh"
else
  log "graphify-mcp already installed."
fi

# 8. Refresh AI payload (prompts, skills, commands, agents), preserving Boat's built-in `boat` skill.
log "Installing AI payload for Claude, Codex, Antigravity, and OpenCode..."
boat_backup=$(mktemp -d)
for sdir in \
  ".claude/skills" \
  ".codex/skills" \
  ".config/opencode/skills" \
  ".gemini/config/skills"; do
  if [ -d "$HOME/$sdir/boat" ]; then
    mkdir -p "$boat_backup/$sdir"
    cp -a "$HOME/$sdir/boat" "$boat_backup/$sdir/boat"
  fi
done

rm -rf \
  "$HOME/.claude/skills" "$HOME/.claude/commands" "$HOME/.claude/agents" \
  "$HOME/.codex/skills" "$HOME/.codex/agents" \
  "$HOME/.agents/skills" \
  "$HOME/.gemini/config/skills" "$HOME/.gemini/config/agents" \
  "$HOME/.config/opencode/skills" "$HOME/.config/opencode/commands" "$HOME/.config/opencode/agents"

tar -xzf /tmp/ai-payload.tar.gz -C "$HOME"
rm -f /tmp/ai-payload.tar.gz

for sdir in \
  ".claude/skills" \
  ".codex/skills" \
  ".config/opencode/skills" \
  ".gemini/config/skills"; do
  if [ -d "$boat_backup/$sdir/boat" ] && [ ! -e "$HOME/$sdir/boat" ]; then
    mkdir -p "$HOME/$sdir"
    cp -a "$boat_backup/$sdir/boat" "$HOME/$sdir/boat"
  fi
done
rm -rf "$boat_backup"

# 9. Clean Boat-only MCP config for Antigravity (standalone + T3 Code profile dir).
#    sha256("antigravity") = ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32
agy_t3_cfg="$HOME/.t3/userdata/providers/antigravity/ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32/config"
mkdir -p "$HOME/.gemini/config" "$agy_t3_cfg"
cat > "$HOME/.gemini/config/mcp_config.json" <<'MCP_EOF'
{
  "mcpServers": {
    "codebase-memory": {
      "command": "/home/user/.local/bin/codebase-memory-mcp",
      "disabled": false
    },
    "graphify": {
      "command": "/home/user/.local/share/graphify-mcp/run.sh",
      "disabled": false
    },
    "boat-docs": {
      "disabled": false,
      "serverUrl": "https://docs.boat.dev/mcp"
    },
    "cloudflare-docs": {
      "disabled": false,
      "serverUrl": "https://docs.mcp.cloudflare.com/mcp"
    },
    "context7": {
      "disabled": false,
      "serverUrl": "https://mcp.context7.com/mcp"
    }
  }
}
MCP_EOF
cp "$HOME/.gemini/config/mcp_config.json" "$agy_t3_cfg/mcp_config.json"
chmod 600 "$HOME/.gemini/config/mcp_config.json" "$agy_t3_cfg/mcp_config.json"

# 10. Secret hygiene audit: guarantee NO credentials or env-injected files exist in the snapshot.
rm -rf \
  "$HOME/.config/tailscale" \
  "$HOME/.claude/settings.json" \
  "$HOME/.codex/config.toml" \
  "$HOME/.codex/auth.json" \
  "$HOME/.config/opencode/opencode.json" \
  "$HOME/.gemini/antigravity-cli/antigravity-oauth-token" \
  "$HOME/.t3/userdata/settings.json" \
  "$HOME/.t3/userdata/secrets" \
  "$HOME/.t3boat/env"

log "Installed versions:"
printf '  agy:      %s\n' "$("$HOME/.local/bin/agy" --version | head -n1)"
printf '  opencode: %s\n' "$("$HOME/.local/bin/opencode" --version | head -n1)"
printf '  t3:       %s\n' "$(t3 --version | head -n1)"
printf '  claude:   %s\n' "$(claude --version | head -n1)"
printf '  codex:    %s\n' "$(codex --version | head -n1)"
printf '  java:     %s\n' "$(java -version 2>&1 | head -n1)"
printf '  cbm:      %s\n' "$("$HOME/.local/bin/codebase-memory-mcp" --version | head -n1)"
printf '  skills:   claude=%d codex=%d agy=%d opencode=%d\n' \
  "$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)" \
  "$(find "$HOME/.agents/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)" \
  "$(find "$HOME/.gemini/config/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)" \
  "$(find "$HOME/.config/opencode/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
REMOTE_EOF

log "Uploading and running provisioning script on $sid..."
prov_b64=$(base64 -w 0 "$provision_script")
boat exec "$sid" --timeout 600 -- \
  "printf '%s' '$prov_b64' | base64 -d > /tmp/provision.sh && chmod +x /tmp/provision.sh && \
   AGY_VERSION=$(printf '%q' "$AGY_VERSION") \
   AGY_URL=$(printf '%q' "$AGY_URL") \
   AGY_SHA256_SRI=$(printf '%q' "$AGY_SHA256_SRI") \
   OPENCODE_VERSION=$(printf '%q' "$OPENCODE_VERSION") \
   OPENCODE_URL=$(printf '%q' "$OPENCODE_URL") \
   OPENCODE_SHA256_HEX=$(printf '%q' "$OPENCODE_SHA256_HEX") \
   CBM_VERSION=$(printf '%q' "$CBM_VERSION") \
   GRAPHIFY_VERSION=$(printf '%q' "$GRAPHIFY_VERSION") \
   T3_VERSION=$(printf '%q' "$T3_VERSION") \
   bash /tmp/provision.sh && rm -f /tmp/provision.sh"

# 6. Save snapshot and wait until ready.
log "Saving snapshot '$SNAPSHOT_NAME' from $sid..."
boat snapshot "$sid" "$SNAPSHOT_NAME" --json >/dev/null

log "Waiting for snapshot '$SNAPSHOT_NAME' to become ready..."
for _ in $(seq 1 100); do
  status=$(boat snapshots --json 2>/dev/null | jq -rs --arg n "$SNAPSHOT_NAME" '
    [ .[] | (.named // .savedSnapshots // .saved_snapshots // .snapshots // (if type == "array" then . else [.] end))[]? ]
    | map(select((type == "object") and (.name? == $n)))
    | first
    | .status? // empty
  ')
  case "$status" in
    ready)
      log "Snapshot '$SNAPSHOT_NAME' is ready!"
      exit 0
      ;;
    error|failed)
      echo "Snapshot '$SNAPSHOT_NAME' entered error state!" >&2
      exit 1
      ;;
  esac
  sleep 3
done

echo "Timed out waiting for snapshot '$SNAPSHOT_NAME' to become ready." >&2
exit 1
