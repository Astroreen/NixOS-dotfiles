# Shared helpers for the agent/command/skill payload modules. Each payload item
# is one Nix definition (body + metadata); this file renders it into a separate
# Markdown frontmatter per CLI, because opencode and claude-code disagree on
# field names and value formats (and opencode forwards unknown agent fields to
# the model provider, so one shared header is not an option).
#
# Google Antigravity (`agy`) is a third target with its own rules: only `name`
# and `description` in the header, skills under ~/.gemini/config/skills and
# custom agents under ~/.gemini/config/agents, and no file-based slash commands
# (its own importer turns command files into skills, so commands ship as skills
# here too).
#
# OpenAI Codex (`codex`) is a fourth target: skills and slash commands land as
# real files under ~/.agents/skills (Codex skips SKILL.md symlinks into
# /nix/store and has no file-based commands), and custom agents land as TOML
# files under ~/.codex/agents/<name>.toml.
{ lib, pkgs }:
let
  targets = [
    "opencode"
    "claude-code"
    "antigravity"
    "codex"
  ];

  # `tools` uses opencode tool names as the shared vocabulary. This maps them to
  # claude-code names; opencode-only tools map to nothing. Names missing here
  # (MCP tools, wildcards) are passed through verbatim.
  claudeToolNames = {
    bash = [ "Bash" ];
    edit = [
      "Edit"
      "NotebookEdit"
    ];
    write = [ "Write" ];
    read = [ "Read" ];
    grep = [ "Grep" ];
    glob = [ "Glob" ];
    lsp = [ "LSP" ];
    webfetch = [ "WebFetch" ];
    websearch = [ "WebSearch" ];
    task = [ "Agent" ];
    todowrite = [ "TodoWrite" ];
    skill = [ "Skill" ];
    question = [ "AskUserQuestion" ];
    list = [ ];
    patch = [ ];
    todoread = [ ];
  };

  claudeTools = names: lib.unique (lib.concatMap (n: claudeToolNames.${n} or [ n ]) names);
  enabledTools = tools: lib.attrNames (lib.filterAttrs (_: on: on) tools);
  disabledTools = tools: lib.attrNames (lib.filterAttrs (_: on: !on) tools);

  # claude-code only knows eight named colors, opencode wants a hex code. The
  # hex color is binned by hue so one `color` value serves both CLIs; greys and
  # non-hex values (opencode theme names) yield no claude color.
  claudeColor =
    color:
    let
      hex = lib.toLower (lib.removePrefix "#" color);
      channel = i: lib.fromHexString (builtins.substring i 2 hex) * 1.0;
      r = channel 0;
      g = channel 2;
      b = channel 4;
      max = lib.max r (lib.max g b);
      min = lib.min r (lib.min g b);
      d = max - min;
      rawHue =
        if max == r then
          60 * ((g - b) / d)
        else if max == g then
          60 * ((b - r) / d + 2)
        else
          60 * ((r - g) / d + 4);
      hue = if rawHue < 0 then rawHue + 360 else rawHue;
      bins = [
        {
          upTo = 15;
          name = "red";
        }
        {
          upTo = 45;
          name = "orange";
        }
        {
          upTo = 70;
          name = "yellow";
        }
        {
          upTo = 160;
          name = "green";
        }
        {
          upTo = 200;
          name = "cyan";
        }
        {
          upTo = 250;
          name = "blue";
        }
        {
          upTo = 290;
          name = "purple";
        }
        {
          upTo = 345;
          name = "pink";
        }
        {
          upTo = 360;
          name = "red";
        }
      ];
    in
    if color == null || builtins.match "#?[0-9a-fA-F]{6}" color == null || d == 0 then
      null
    else
      (lib.findFirst (bin: hue < bin.upTo) { name = "red"; } bins).name;

  # Minimal YAML emitter: nested attrsets become block mappings, every other
  # value is written as JSON (valid YAML flow syntax, quotes all strings).
  yamlKey = k: if builtins.match "[A-Za-z0-9_-]+" k != null then k else builtins.toJSON k;
  leadingKeys = [
    "name"
    "description"
  ];
  orderedKeys =
    attrs:
    lib.filter (k: attrs ? ${k}) leadingKeys ++ lib.subtractLists leadingKeys (lib.attrNames attrs);
  toYaml =
    indent: attrs:
    lib.concatMapStrings (
      k:
      let
        v = attrs.${k};
      in
      if lib.isAttrs v && v != { } then
        "${indent}${yamlKey k}:\n${toYaml "${indent}  " v}"
      else
        "${indent}${yamlKey k}: ${builtins.toJSON v}\n"
    ) (orderedKeys attrs);

  # Unset fields are null; dropping them here (after the passthrough attrsets
  # are merged in) also lets `claude.color = null` remove a generated field.
  dropNulls =
    attrs:
    lib.mapAttrs (_: v: if lib.isAttrs v then dropNulls v else v) (
      lib.filterAttrs (_: v: v != null) attrs
    );

  nonEmpty = v: if v == { } || v == [ ] || v == "" then null else v;

  render =
    header: body:
    "---\n${toYaml "" (dropNulls header)}---\n\n${
      if lib.isPath body then builtins.readFile body else body
    }";
in
{
  inherit
    targets
    claudeTools
    enabledTools
    disabledTools
    claudeColor
    dropNulls
    nonEmpty
    ;

  # Header attrset + body (path or text) → Markdown file text.
  inherit render;

  # Included items deployed to `target`, as `{ <name> = <file text>; }` for the
  # programs.{opencode,claude-code}.{agents,commands} attrset options.
  # `header name definition` builds that CLI's frontmatter.
  renderIncluded =
    definitions: include: target: header:
    lib.genAttrs (lib.filter (name: lib.elem target definitions.${name}.targets) include) (
      name: render (header name definitions.${name}) definitions.${name}.body
    );

  # Same selection as `renderIncluded`, but keeping the definitions, for targets
  # that post-process the body (Antigravity/Codex commands become skills, Codex
  # agents become TOML).
  includedFor =
    definitions: include: target:
    lib.genAttrs (lib.filter (name: lib.elem target definitions.${name}.targets) include) (
      name: definitions.${name}
    );

  # Antigravity and Codex have no file-based slash commands: commands ship as
  # skills, swapping `$ARGUMENTS`/`{{args}}` for an instruction.
  skillCommandBody =
    body:
    lib.replaceStrings
      [
        "$ARGUMENTS"
        "{{args}}"
      ]
      [
        "Apply this to what the user asked for."
        "Apply this to what the user asked for."
      ]
      body;

  # Copy files as real files (dereferencing symlinks) into `~/<dir>` on
  # activation, tracking the managed names in `~/<dir>/<manifest>`. Items
  # dropped from the repo disappear while runtime-created ones stay. Used when
  # a CLI writes to the same dir (Antigravity) or skips /nix/store symlinks
  # (Codex skills/commands).
  copySync =
    {
      name,
      dir,
      manifest ? ".nix-managed-${name}",
      files,
    }:
    let
      manifestPath = "${dir}/${manifest}";
      src = pkgs.linkFarm "ai-sync-${name}" (
        lib.mapAttrsToList (fileName: path: {
          name = fileName;
          inherit path;
        }) files
      );
      managed = pkgs.writeText "ai-sync-${name}-managed" (
        lib.concatMapStrings (fileName: "${fileName}\n") (lib.attrNames files)
      );
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dir="$HOME/${dir}"
      if [ -f "$HOME/${manifestPath}" ]; then
        while IFS= read -r item; do
          if [ -n "$item" ]; then run rm -rf "$dir/$item"; fi
        done < "$HOME/${manifestPath}"
      fi
      run mkdir -p "$dir"
      run cp -rL ${src}/. "$dir/"
      run cp --no-preserve=mode ${managed} "$HOME/${manifestPath}"
      while IFS= read -r item; do
        if [ -n "$item" ]; then run chmod -R u+w "$dir/$item"; fi
      done < "$HOME/${manifestPath}"
    '';

  # mkDefault on every leaf instead of whole attrsets, so a profile can override
  # a single field (e.g. `tools.edit = true`) and keep the bundled siblings.
  mkDefaultLeaves =
    let
      go = v: if lib.isAttrs v then lib.mapAttrs (_: go) v else lib.mkDefault v;
    in
    go;

  # Options every payload kind shares. `toolsDescription` explains what `tools`
  # turns into for that kind, since the CLIs give it different meanings.
  commonOptions =
    { toolsDescription }:
    with lib;
    {
      description = mkOption {
        type = types.str;
        description = "Short description shown in the CLI pickers (`description` in both headers).";
      };

      tools = mkOption {
        type = types.attrsOf types.bool;
        default = { };
        example = {
          edit = false;
          write = false;
        };
        description = ''
          Tool switches keyed by opencode tool name (`bash`, `edit`, `write`,
          `read`, `grep`, `glob`, `lsp`, `webfetch`, `websearch`, `task`, ...).
          ${toolsDescription}
        '';
      };

      targets = mkOption {
        type = types.listOf (types.enum targets);
        default = targets;
        description = "CLIs this item is deployed to.";
      };

      extra = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Extra frontmatter fields written to both headers.";
      };

      opencode = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = {
          model = "anthropic/claude-sonnet-4-5";
        };
        description = ''
          Extra opencode frontmatter (e.g. `model`, `top_p`, `permission`).
          Wins over generated fields; `null` removes a generated field.
        '';
      };

      claude = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = {
          model = "sonnet";
        };
        description = ''
          Extra claude-code frontmatter (e.g. `model`, `effort`,
          `permissionMode`). Wins over generated fields; `null` removes a
          generated field.
        '';
      };

      antigravity = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = {
          triggers = [ "review my diff" ];
        };
        description = ''
          Extra Antigravity frontmatter (skill or custom-agent fields, e.g.
          `triggers`). Wins over generated fields; `null` removes a generated
          field.
        '';
      };

      codex = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = {
          sandbox_mode = "read-only";
        };
        description = ''
          Extra Codex fields (SKILL.md frontmatter for skills/commands, or
          TOML keys such as `model`, `model_reasoning_effort`, `sandbox_mode`
          for custom agents). Wins over generated fields; `null` removes a
          generated field.
        '';
      };
    };

  # Bundled payload file for `name`, used as the option default when it exists.
  # Items a profile adds itself have no such file and must set the option.
  optionalDefault = path: lib.optionalAttrs (builtins.pathExists path) { default = path; };

  # Eval-time guard against typos in an include list (assertions stay lazy,
  # unlike a bare `assert`, which would force cfg during merging).
  includeAssertion = option: include: available: {
    assertion = lib.all (name: lib.elem name available) include;
    message = ''
      ${option}: unknown entries: ${toString (lib.subtractLists available include)}
      Available: ${toString available}'';
  };
}
