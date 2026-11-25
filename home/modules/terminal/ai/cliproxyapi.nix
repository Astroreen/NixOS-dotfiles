# Generic Home Manager module for routing AI CLIs (Claude Code, Codex, OpenCode)
# through a CLIProxyAPI server without ever placing the client API key in the
# Nix store or repository.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai.cliproxyapi;
  baseUrl = lib.removeSuffix "/" cfg.baseUrl;

  codexUpdater = pkgs.writeScript "cliproxyapi-update-codex-toml" ''
    #!${lib.getExe pkgs.python3}
    import json
    import re
    import sys
    from pathlib import Path

    cfg_path = Path(sys.argv[1])
    base_url = sys.argv[2]
    api_key = sys.argv[3]

    text = cfg_path.read_text(encoding="utf-8") if cfg_path.exists() else ""
    lines = text.splitlines()

    # 1. Remove any existing [model_providers.cliproxy] / [model_providers.cliproxyapi] table.
    cleaned = []
    skipping = False
    for line in lines:
        stripped = line.strip()
        if re.match(r"^\[model_providers\.cliproxy(api)?\]\s*(#.*)?$", stripped):
            skipping = True
            continue
        if skipping and re.match(r"^\[", stripped):
            skipping = False
        if not skipping:
            cleaned.append(line)

    # 2. Ensure top-level `model_provider = "cliproxy"` appears before the first [table].
    out = []
    inserted = False
    for line in cleaned:
        stripped = line.strip()
        if not inserted and stripped.startswith("["):
            out.append('model_provider = "cliproxy"')
            inserted = True
        if not inserted and re.match(r"^model_provider\s*=", stripped):
            out.append('model_provider = "cliproxy"')
            inserted = True
            continue
        out.append(line)
    if not inserted:
        out.append('model_provider = "cliproxy"')

    while out and out[-1] == "":
        out.pop()

    # json.dumps produces valid TOML basic strings for URLs and hex/ASCII keys.
    section = [
        "",
        "[model_providers.cliproxy]",
        'name = "CLIProxyAPI"',
        f"base_url = {json.dumps(base_url + '/v1')}",
        'wire_api = "responses"',
        "requires_openai_auth = false",
        "supports_websockets = true",
        "supports_standalone_web_search = true",
        f"experimental_bearer_token = {json.dumps(api_key)}",
    ]

    tmp_path = cfg_path.with_suffix(".toml.tmp")
    tmp_path.write_text("\n".join(out + section) + "\n", encoding="utf-8")
    tmp_path.replace(cfg_path)
  '';
in
{
  options.custom.ai.cliproxyapi = {
    enable = lib.mkEnableOption "route AI CLIs (Claude Code, Codex, OpenCode) through a CLIProxyAPI server";

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8317";
      description = ''
        Origin URL of the CLIProxyAPI server (without trailing slash or `/v1`).
      '';
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/cliproxyapi/api-key";
      description = ''
        Path to a mode-0600 file holding the CLIProxyAPI client API key.
        Never stored in Nix; if missing or empty during activation, Claude/Codex
        config patching is skipped with a warning so activation succeeds on a
        fresh host before the key is copied.
      '';
    };

    clients = {
      claude = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Merge CLIProxyAPI env vars into ~/.claude/settings.json.";
      };

      codex = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Configure [model_providers.cliproxy] in ~/.codex/config.toml.";
      };

      opencode = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Point OpenCode's openai and google providers at CLIProxyAPI.
          Anthropic is deliberately excluded: Claude subscriptions must only be
          used through Claude Code to avoid account bans.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation = {
      # Ensure apiKeyFile exists (0600) so OpenCode's `{file:...}` interpolation
      # never fails config parsing on a fresh host before the key is provisioned.
      cliproxyapiEnsureKeyFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        keyFile=${lib.escapeShellArg cfg.apiKeyFile}
        if [ ! -f "$keyFile" ]; then
          install -D -m 600 /dev/null "$keyFile"
        fi
      '';

      cliproxyapiClaude = lib.mkIf cfg.clients.claude (
        lib.hm.dag.entryAfter [ "writeBoundary" "claudeDefaultModel" "cliproxyapiEnsureKeyFile" ] ''
          keyFile=${lib.escapeShellArg cfg.apiKeyFile}
          key=$(tr -d '\r\n' < "$keyFile" 2>/dev/null || true)
          if [ -z "$key" ]; then
            echo "cliproxyapi: $keyFile is empty; skipping ~/.claude/settings.json update"
          else
            (
              umask 077
              cfg="$HOME/.claude/settings.json"
              mkdir -p "$HOME/.claude"
              [ -s "$cfg" ] || echo '{}' > "$cfg"
              ${lib.getExe pkgs.jq} \
                --arg url ${lib.escapeShellArg baseUrl} \
                --arg key "$key" \
                '.env = ((.env // {}) + {
                  ANTHROPIC_BASE_URL: $url,
                  ANTHROPIC_AUTH_TOKEN: $key,
                  ANTHROPIC_API_KEY: "",
                  CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY: "1",
                  API_TIMEOUT_MS: "600000"
                })' \
                "$cfg" > "$cfg.tmp"
              mv "$cfg.tmp" "$cfg"
            )
          fi
        ''
      );

      cliproxyapiCodex = lib.mkIf cfg.clients.codex (
        lib.hm.dag.entryAfter [ "writeBoundary" "codexDefaultModel" "cliproxyapiEnsureKeyFile" ] ''
          keyFile=${lib.escapeShellArg cfg.apiKeyFile}
          key=$(tr -d '\r\n' < "$keyFile" 2>/dev/null || true)
          if [ -z "$key" ]; then
            echo "cliproxyapi: $keyFile is empty; skipping ~/.codex/config.toml update"
          else
            (
              umask 077
              mkdir -p "$HOME/.codex"
              ${codexUpdater} "$HOME/.codex/config.toml" ${lib.escapeShellArg baseUrl} "$key"
            )
          fi
        ''
      );
    };

    # Deliberately omit `anthropic`: Claude OAuth subscriptions should only be
    # used via Claude Code itself, never from third-party clients like OpenCode.
    programs.opencode.settings.provider = lib.mkIf cfg.clients.opencode {
      openai.options = {
        baseURL = "${baseUrl}/v1";
        apiKey = "{file:${cfg.apiKeyFile}}";
      };
      google.options = {
        baseURL = "${baseUrl}/v1beta";
        apiKey = "{file:${cfg.apiKeyFile}}";
      };
    };
  };
}
