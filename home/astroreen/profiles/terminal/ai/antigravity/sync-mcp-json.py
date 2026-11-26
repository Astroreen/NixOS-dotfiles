import json
import sys
from pathlib import Path

cfg_dir = Path(sys.argv[1])
payload_path = Path(sys.argv[2])

cfg_dir.mkdir(parents=True, exist_ok=True)
cfg_path = cfg_dir / "mcp_config.json"
manifest_path = cfg_dir / ".nix-managed-mcp"

desired = json.loads(payload_path.read_text(encoding="utf-8"))
previous = (
    {
        line.strip()
        for line in manifest_path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }
    if manifest_path.exists()
    else set()
)

raw = cfg_path.read_text(encoding="utf-8").strip() if cfg_path.exists() else ""
data = json.loads(raw) if raw else {}
if not isinstance(data, dict):
    data = {}
servers = data.get("mcpServers")
if not isinstance(servers, dict):
    servers = {}
    data["mcpServers"] = servers

# Remove servers previously managed by Nix that are no longer enabled.
for old_name in sorted(previous - set(desired.keys())):
    servers.pop(old_name, None)

# Preserve pre-existing manual entries even when a name collides.
managed_now: list[str] = []
for name in sorted(desired.keys()):
    if name in servers and name not in previous:
        continue
    servers[name] = desired[name]
    managed_now.append(name)

tmp_path = cfg_path.with_suffix(".json.tmp")
tmp_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
tmp_path.replace(cfg_path)

manifest_tmp = manifest_path.with_suffix(".tmp")
manifest_tmp.write_text(
    "\n".join(managed_now) + ("\n" if managed_now else ""),
    encoding="utf-8",
)
manifest_tmp.replace(manifest_path)
