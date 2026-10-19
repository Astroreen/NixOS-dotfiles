{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  opencodePackage =
    inputs.opencode-v2.packages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs
      (old: {
        # Upstream's src fileset (nix/node_modules.nix) omits the repo-root
        # script/ dir, so packages/cli/script/build.ts fails to resolve
        # ../../../script/native-arch. Vendor that single file straight from
        # the same pinned input; it is self-contained (only node:fs/promises).
        postPatch = (old.postPatch or "") + ''
          mkdir -p script
          cp ${inputs.opencode-v2}/script/native-arch.ts script/native-arch.ts
        '';

        postInstall = (old.postInstall or "") + ''
          wrapProgram "$out"/bin/opencode --set OPENCODE_DISABLE_AUTOUPDATE true
        '';
      });
in
{
  imports = [
    ../../../../../modules/terminal/ai # default.nix of ai folder
  ];

  # Meridian proxy + its OpenCode plugin. The legacy v1 plugin (plugin/meridian.ts)
  # does not load under opencode v2. The v2 plugin is loaded from the pre-compiled
  # dist/meridian-v2/ bundle (self-contained JS, exports { id, setup } per v2 API);
  # meridian.nix points at it. Integration routes anthropic models through the proxy.
  custom.ai = {
    meridian = {
      enable = false;
      enableOpencodeIntegration = false;
    };

    # Global prompt (AGENTS.md for opencode, CLAUDE.md for claude-code). The
    # module appends the caveman always-on snippet when it is enabled.
    prompt = ../CustomPrompt.md;

    # Bundled payload (home/modules/terminal/ai/<kind>/<name>.md, metadata in
    # <kind>/definitions.nix). Shared with claude-code: the modules render a
    # header per CLI and wire both programs from these lists. Per-item tweaks
    # go in `<kind>.definitions.<name>` (e.g. `agent.definitions.atlas.temperature`).
    agent.local.include = [
      "atlas"
      "explore"
      "hephaestus"
      "librarian"
      "metis"
      "momus"
      "multimodal-looker"
      "oracle"
      "prometheus"
      "scribe"
      "sisyphus"
      "sisyphus-junior"
    ];

    command.local.include = [
      "goal"
      "handoff"
      "hyperplan"
      "refactor"
      "remove-ai-slops"
      "start-work"
    ];

    skill = {
      # Bundled local skills (home/modules/terminal/ai/skills/<name>) to deploy.
      local.include = [
        "commit-message"
        "design-taste-frontend"
        "docx"
        "frontend-design"
        "spike"
        "subagent-driven-development"
        "systematic-debugging"
        "test-driven-development"
        # user-invoked: its SKILL.md sets disable-model-invocation, so the model
        # never auto-loads it (pick it via /skills or @unslop); from
        # github:cursor/plugins pstack/skills/unslop
        "unslop"
        "verify-before-done"
      ];

      # Caveman — on-demand only (alwaysOn off since 2026-10-12, experiment).
      # include trims the upstream set: keep core + local tools + native
      # workflow guards; drop the Caveman Cloud suite (setup, discover,
      # evidence-review, manage, optimize, learn) — no gateway in use.
      caveman = {
        enable = true;
        alwaysOn = false;
        include = [
          # core + local skills
          "caveman"
          "caveman-commit"
          "caveman-review"
          "caveman-compress"
          "caveman-help"
          "caveman-stats"
          "caveman-explore"
          "cavecrew"
          # native workflow guards (classified, auto-applied by task type)
          "native"
          "investigate-first"
          "lean-build"
          "migration"
          "safe-refactor"
          "surgical-patch"
          "verify-and-stop"
          # infra referenced by the skills above
          "compile.mjs"
          "verbs-gate.mjs"
          "engine-mcp-tools.json"
          "registry.json"
        ];
      };

      # Matt Pocock skills — fetched from the mattpocock-skills flake input.
      # To adopt a new upstream skill: `nix flake update mattpocock-skills`,
      # then add its name here.
      matt-pocock = {
        enable = true;
        include = [
          # engineering
          "tdd"
          "diagnosing-bugs"
          "code-review"
          "pr"
          "retro"
          "codebase-design"
          # productivity
          "grilling"
          "grill-me"
          "handoff"
          "writing-for-agents"
          "wait-what"
        ];
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    # OpenCode v2 from the upstream flake; nixpkgs still packages the v1 line
    # (opencode-ai 1.19.0). t3code >= 0.0.46 reports opencode >= 2.0.18 as
    # "supported" and 1.14.19-1.x as "graceful" (limited compatibility).
    # OPENCODE_DISABLE_AUTOUPDATE keeps the nix-managed binary from
    # self-updating (upstream opencode.nix does not set it).
    #
    # opencode-task-fallback.patch is deliberately NOT applied: it targets the
    # v1 source layout (packages/opencode/src/tool/*) and v2 rewrote the
    # subagent/job lifecycle (packages/core/src/session/subagent-completion.ts).
    # The fallback-abort flow must be re-verified against v2 before porting it.
    package = opencodePackage;

    settings = {
      # Yolo: stop permission prompts. Only external_directory (and doom_loop)
      # default to "ask" — bash/read/edit/webfetch are already "allow".
      # Scoped to external_directory so the default .env / .env.* read deny
      # (secret protection) stays intact.
      permission = {
        external_directory = "allow";
        bash = "allow";
        read = "allow";
        edit = "allow";
        webfetch = "allow";
      };

      # opencode v2 only loads plugins that `export default { id, effect | setup }`.
      # Dropped because their published releases are still the v1 function API:
      # @franlol/opencode-md-table-formatter (0.0.6, @opencode-ai/plugin >=0.13.7),
      # opencode-anthropic-auth (0.0.13, named export only),
      # opencode-claude-auth (2.2.1, peer dep on the v1 @opencode-ai/plugin).
      # Notifier is the only one with a v2 entry (0.8.1: default = { id,
      # server, setup }). Keep it unpinned: a "name@version" spec makes v2
      # resolve a stale v1 install from ~/.cache/opencode and fail with
      # "Plugin must export a default definition...", while the bare name
      # resolves to the 0.8.1 npm install and loads (server + tui features).
      plugin = [
        "@mohak34/opencode-notifier"
      ];
    };

    tui = {
      theme = "gruvbox";
    };

    # Headless server, started with the user systemd session (default.target).
    # Loopback only. Note: v2 `serve` dropped --mdns (was LAN discovery).
    web = {
      enable = false;
      extraArgs = [
        "--hostname"
        "0.0.0.0"
        "--port"
        "4096"
      ];
    };
  };

  home = {
    activation = {
      # The opencode background service (`opencode serve --service`) caches the
      # resolved config per location and never invalidates it: the Linux build
      # has no config watcher ("watcher backend not supported"), so a changed
      # opencode.json is ignored until the service restarts. Restart it here
      # when the generated config actually changed (hash stamp), and only when
      # the service is already running — a stopped service reads the fresh
      # config on its next on-demand spawn anyway.
      restartOpencodeService = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        STATE_DIR="${config.home.homeDirectory}/.local/state/opencode"
        CONFIG="${config.xdg.configHome}/opencode/opencode.json"
        STAMP="$STATE_DIR/hm-opencode-config.sha256"
        mkdir -p "$STATE_DIR"
        hash=$(sha256sum "$CONFIG" | cut -d" " -f1)
        if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$hash" ]; then
          echo "opencode.json unchanged, skipping opencode service restart"
        else
          echo "$hash" > "$STAMP"
          for reg in "$STATE_DIR"/service*.json; do
            [ -e "$reg" ] || continue
            pid=$(grep -o '"pid":[0-9]*' "$reg" | cut -d: -f2)
            if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
              echo "opencode.json changed, restarting opencode background service"
              ${config.programs.opencode.package}/bin/opencode service restart || echo "warning: opencode service restart failed"
              break
            fi
          done
        fi
      '';
    };

    shellAliases = {
      oc = "opencode";
    };
  };

  # Desktop entry: open a kitty terminal running the OpenCode TUI.
  xdg.desktopEntries.opencode = {
    name = "OpenCode";
    genericName = "AI Coding Agent";
    exec = "${pkgs.kitty}/bin/kitty --title opencode ${config.programs.opencode.package}/bin/opencode";
    terminal = false;
    categories = [
      "Development"
      "IDE"
    ];
    icon = "utilities-terminal";
    comment = "OpenCode AI coding agent in a terminal";
  };
}
