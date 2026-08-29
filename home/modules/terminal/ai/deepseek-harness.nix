{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.ai.deepseekHarness;

  dshPackage = pkgs.callPackage ../../../package/deepseek-harness.nix { };

  # `dsh web` loads @deepseek-ai/cordis-plugin-hmr, whose constructor throws
  # "--expose-internals is required for HMR service" unless Node is launched with
  # that flag. The row's `disabled: true` patch (used by upstream's dsh-web-app
  # bundle) does not suppress the row in this rc build, and Node rejects the flag
  # inside NODE_OPTIONS, so the service bypasses the `bin/dsh` shell wrapper and
  # launches the ESM entrypoint through Node directly with the flag. nodejs_22 is
  # the interpreter the package pins for build+runtime.
  nodeBin = lib.getExe' pkgs.nodejs_22 "node";
  dshEntry = "${dshPackage}/lib/node_modules/@deepseek-ai/dsh/lib/bin.js";

  yamlFormat = pkgs.formats.yaml { };

  # cordis.patch.yml MUST be a top-level YAML ARRAY of loader patch entries
  # (PatchOptions[] from @deepseek-ai/cordis-plugin-include). Each entry patches
  # an existing base-bundle row by id (whole-`config` replace) or inserts new
  # rows. We patch `system-prompt` (persona) and `agent-default-model`
  # (provider+model). `extraConfig` is a raw list of extra patch entries appended
  # verbatim. Model/provider CONNECTION config (baseURL/api) does NOT belong here
  # -- it lives in settings.yaml's `llm-pi-ai` namespace (see below).
  cordisPatchEntries =
    lib.optional (cfg.settings.systemPrompt != null) {
      id = "system-prompt";
      config.persona = cfg.settings.systemPrompt;
    }
    ++ lib.optional (cfg.settings.provider != null && cfg.settings.model != null) {
      id = "agent-default-model";
      config = {
        provider = cfg.settings.provider;
        model = cfg.settings.model;
      };
    }
    ++ cfg.settings.extraConfig;

  cordisPatchFile = yamlFormat.generate "cordis.patch.yml" cordisPatchEntries;

  # settings.yaml is a plain YAML MAP of namespace sections (hot-reloaded, parsed
  # by @deepseek-ai/dsh-settings-file, which throws unless the root is a map --
  # opposite shape to cordis.patch.yml). We declare a custom OpenAI-compatible
  # provider route under the `llm-pi-ai` namespace so the user's local proxy
  # (e.g. Meridian) is selectable.
  #
  # A hand-declared llm-pi-ai route is only VALID when it lists at least one
  # model: @deepseek-ai/dsh-llm-pi-ai's resolveRouteModels() rejects a
  # non-catalog route that resolves zero models ("... resolves no models ...",
  # lib/index.js L624), so a model-less route is refused/unserviceable and never
  # appears as an editable provider in the web Models page. We therefore only
  # materialize the route when BOTH `provider` and `model` are set (a model
  # guarantees the required >=1 model entry). The route id must also be a
  # lowercase settings/credential key (the web custom-provider card enforces
  # ROUTE_PATTERN /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/ and deriveKeyRef uppercases it
  # into a POSIX env-var name) -- enforced by an assertion below. For an
  # OpenAI-compatible proxy you may alternatively point a BUILT-IN provider
  # (e.g. deepseek-official) at your baseURL from the web UI instead.
  emitProviderRoute = cfg.settings.provider != null && cfg.settings.model != null;

  providerRoute = {
    api = "openai-completions";
  }
  // lib.optionalAttrs (cfg.settings.baseUrl != null) { baseURL = cfg.settings.baseUrl; }
  // lib.optionalAttrs (cfg.settings.model != null) {
    models = [ { id = cfg.settings.model; } ];
  };

  settingsFile = yamlFormat.generate "settings.yaml" {
    "llm-pi-ai".providers.${toString cfg.settings.provider} = providerRoute;
  };
in
{
  options = with lib; {
    custom.ai.deepseekHarness = {
      enable = mkEnableOption "DeepSeek Harness (dsh) coding-agent CLI and web UI server";

      settings = mkOption {
        description = "DeepSeek Harness settings, materialized into $DSH_HOME/cordis.patch.yml and settings.yaml.";
        default = { };
        type = types.submodule {
          options = {
            host = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "Host/interface the dsh web server binds to.";
            };

            port = mkOption {
              type = types.int;
              default = 3080;
              description = "Port for the dsh web UI server (dsh web --port).";
            };

            dshHome = mkOption {
              type = types.either types.str types.path;
              default = "${config.home.homeDirectory}/.dsh";
              description = "DSH_HOME config root (sessions, profiles, cordis.patch.yml, settings.yaml).";
            };

            model = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Default model id (also exported as DSH_MODEL to the service).";
            };

            provider = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Provider route id; declares an llm-pi-ai route in settings.yaml and sets agent-default-model.";
            };

            baseUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "OpenAI-compatible baseURL for the provider route (also exported as DEEPSEEK_BASE_URL).";
            };

            systemPrompt = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "System prompt override (patched into the system-prompt row; also exported as DSH_SYSTEM_PROMPT).";
            };

            extraConfig = mkOption {
              type = types.listOf types.attrs;
              default = [ ];
              description = "Extra cordis.patch.yml entries; each a raw patch-entry attrset appended verbatim to the top-level array.";
            };
          };
        };
      };

      plugins = mkOption {
        description = ''
          Declarative dsh plugins to install into a profile on activation via
          `dsh plugin --profile <profile> add <pkg>[@version]`. Everything in dsh
          is a plugin (Cordis framework); plugin packages are ordinary npm
          packages carrying a cordis.patch.yml overlay.
        '';
        default = { };
        example = lib.literalExpression ''
          {
            "@deepseek-ai/dsh-plan-mode" = { profile = "default"; };
          }
        '';
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                package = mkOption {
                  type = types.str;
                  default = name;
                  description = "npm package name of the plugin.";
                };

                version = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Optional pinned version (appended as @<version>).";
                };

                profile = mkOption {
                  type = types.str;
                  default = "default";
                  description = "dsh profile the plugin is installed into.";
                };
              };
            }
          )
        );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # A materialized llm-pi-ai route id doubles as a settings key AND the stem of
    # a credential env-var name (deriveKeyRef), so it must be a lowercase
    # POSIX-safe identifier. A capitalized id like "Meridian" is refused by the
    # web custom-provider card (ROUTE_PATTERN) and cannot round-trip through
    # deriveKeyRef -- fail the build early with an actionable message instead.
    assertions = [
      {
        assertion =
          !emitProviderRoute || builtins.match "[a-z][a-z0-9]*(-[a-z0-9]+)*" cfg.settings.provider != null;
        message = ''
          custom.ai.deepseekHarness.settings.provider = "${toString cfg.settings.provider}" is not a valid
          llm-pi-ai route id. When a model is set the provider id is written as a settings key and turned
          into a credential env-var name, so it must match /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/ (lowercase,
          digits and single dashes, starting with a letter). Use e.g. "meridian" instead of "Meridian".
        '';
      }
    ];

    home = {
      packages = [ dshPackage ];

      activation = {
        # cordis.patch.yml is copied (not symlinked) because dsh may rewrite its
        # config root at runtime and the Nix store is read-only.
        deepseekHarnessConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${cfg.settings.dshHome}"
          cp -f ${cordisPatchFile} "${cfg.settings.dshHome}/cordis.patch.yml"
          chmod 644 "${cfg.settings.dshHome}/cordis.patch.yml"
        '';

        # settings.yaml holds the custom llm-pi-ai provider route. It is
        # hot-reloaded and also written by the app itself (web Models page), so
        # we DEEP-MERGE our route into any existing file (yq, our keys win) rather
        # than overwriting -- preserving other namespaces/providers the user or
        # the running app may have added. Copied (not symlinked) for the same
        # runtime-mutability reason as cordis.patch.yml.
        deepseekHarnessSettings = lib.mkIf emitProviderRoute (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "${cfg.settings.dshHome}"
            dest="${cfg.settings.dshHome}/settings.yaml"
            if [ -f "$dest" ]; then
              ${pkgs.yq-go}/bin/yq eval-all '. as $item ireduce ({}; . * $item)' "$dest" ${settingsFile} > "$dest.tmp"
              mv -f "$dest.tmp" "$dest"
            else
              cp -f ${settingsFile} "$dest"
            fi
            chmod 644 "$dest"
          ''
        );

        # Install declared plugins into their profiles. Idempotent-guarded with
        # `|| true` since plugin add may need network / already be present.
        deepseekHarnessPlugins = lib.mkIf (cfg.plugins != { }) (
          lib.hm.dag.entryAfter [ "deepseekHarnessConfig" ] (
            ''
              export DSH_HOME="${cfg.settings.dshHome}"
            ''
            + lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                _: p:
                let
                  spec = p.package + lib.optionalString (p.version != null) "@${p.version}";
                in
                "${dshPackage}/bin/dsh plugin --profile ${p.profile} add ${spec} || true"
              ) cfg.plugins
            )
          )
        );
      };
    };

    # Long-running dsh web UI server ("start server at boot"). Headless one-shot
    # mode is intentionally not used here (it is not a server). Node is invoked
    # directly with --expose-internals (see nodeBin/dshEntry note above) because
    # the web profile's HMR plugin hard-crashes boot without that flag.
    systemd.user.services.deepseek-harness = {
      Unit = {
        Description = "DeepSeek Harness (dsh) web UI server";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${nodeBin} --expose-internals ${dshEntry} web --host ${cfg.settings.host} --port ${builtins.toString cfg.settings.port} --no-open";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "DSH_HOME=${cfg.settings.dshHome}"
        ]
        ++ lib.optional (cfg.settings.model != null) "DSH_MODEL=${cfg.settings.model}"
        ++ lib.optional (cfg.settings.baseUrl != null) "DEEPSEEK_BASE_URL=${cfg.settings.baseUrl}"
        ++ lib.optional (
          cfg.settings.systemPrompt != null
        ) "DSH_SYSTEM_PROMPT=${cfg.settings.systemPrompt}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
