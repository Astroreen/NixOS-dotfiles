# AGENTS.md: NixOS configuration repository

NixOS flake-based dotfiles. Two hosts (`laptop`, `pc`), user `astroreen`. Home-manager embedded in NixOS via `home-manager.nixosModules.home-manager` (not standalone).

---

## Build commands

Two rules agents get wrong constantly. Read both before running anything:

1. **Host**: never hardcode `laptop` or `pc`. The machine you are on RIGHT NOW is the deploy
   target. Determine it with `hostname -s`; its output is exactly the flake host name (`laptop` or `pc`).
2. **devenv**: scripts (`nixos`, `home`, `nx`, `hm`, `update-flake`, ...) exist ONLY inside the
   `devenv` shell. Interactive `.envrc`/direnv auto-activation does NOT apply to agent/SSH bash
   sessions. Wrap every call as `devenv shell -- <command>`. Run from the repo root.

### Host selection

```bash
hostname -s    # "laptop" or "pc"; use this as <host> in every command below
```

Use `"$(hostname -s)"` substitution, never a literal host name copied from examples. If the output
is neither `laptop` nor `pc`, stop and ask the user which flake host to target.

- `switch` / `test` / `rollback` / `dry-activate` ALWAYS target the current machine (`"$(hostname -s)"`).
- `build` / `dry-build` for the OTHER host only when the user explicitly names that host.

### NixOS (`nixos <action> <host>`, alias `nx`)

```bash
devenv shell -- nixos dry-build "$(hostname -s)"      # Evaluate + show store paths, no side effects
devenv shell -- nixos dry-activate "$(hostname -s)"   # Show what activation would do, no side effects
devenv shell -- nixos test "$(hostname -s)"           # Build + activate, no bootloader entry (safe)
devenv shell -- nixos switch "$(hostname -s)"         # Build + activate + bootloader entry
devenv shell -- nixos build "$(hostname -s)"          # Build only, no activation
devenv shell -- nixos rollback "$(hostname -s)"       # Roll back to previous generation
```

**Always `dry-build` before applying.**

Every `nixos` call runs `git add .` first; unstaged changes are invisible to nixos-rebuild.
Every `nixos` call uses `sudo` after `git add .`; some changes require sudo privileges.
If `sudo` fails with "a terminal is required", the session has no TTY; rebuild must run from an
interactive shell (or sudoers needs `NOPASSWD` for `nixos-rebuild`).

### Home Manager (`home <action> <host>`, alias `hm`)

```bash
devenv shell -- home switch "$(hostname -s)"          # Build + activate HM config
devenv shell -- home build "$(hostname -s)"           # Build only
devenv shell -- home rollback "$(hostname -s)"        # Roll back HM generation
```

HM configs are `homeConfigurations."astroreen@<host>"` in the flake, managed independently from the NixOS system.

### Other

```bash
devenv shell -- update-flake                # nix flake update
devenv shell -- delete-garbage              # nix-collect-garbage --delete-older-than 7d + nix-store --gc
devenv shell -- start-work                  # OpenVPN + DNS setup for work
devenv shell -- stop-work                   # OpenVPN + DNS teardown
devenv shell -- add-work-dns                # DNS only (no VPN start)
devenv shell -- delete-work-dns             # DNS only (no VPN stop)
devenv shell -- sync-caelestia-config       # Merge official caelestia example config into host JSONs (scripts/sync-caelestia-config.py)
devenv shell -- list-generations            # nixos-rebuild list-generations
devenv shell -- delete-generations [N]      # Delete old NixOS generations, keep last N (default 5)
devenv shell -- find-large-files [N] [dir]  # Top-N largest files on disk (default 30, /)
```

### Linting and formatting

These also run inside the devenv shell:

```bash
devenv shell -- statix check .              # Static analysis: antipatterns, deprecated options
devenv shell -- statix fix .                # Auto-fix statix warnings
devenv shell -- deadnix .                   # Find unused bindings/args
devenv shell -- deadnix --edit .            # Auto-remove dead code
devenv shell -- nixfmt <file>.nix           # Format single file (2-space indent)
```

---

## File placement rules

Read this before creating ANY file. Every new file must land at one of these paths. Pick the path
from this table; never guess:

| Path | Scope | What goes there |
|---|---|---|
| `home/` | Home-manager (user-level) | HM config only: `home.*`, `home.packages`, `home.file.*`, `wayland.windowManager.*`, HM `programs.*` |
| `hosts/` | System-level NixOS | System config only: `services.*`, `environment.*`, `hardware.*`, `networking.*`, `virtualisation.*` |
| `home/<user>/`, `hosts/<user>/` | That user only | User-specific settings/files: entry files (`home.nix`, `configuration.nix`), `common/`, host overrides |
| `home/<user>/profiles/`, `hosts/<user>/profiles/` | That user, **preconfigured** | Programs/settings with concrete values already chosen for this user, imported as-is, ready to use |
| `home/modules/`, `hosts/modules/` | **Any user** | Generic modules with **no preconfigured values**. They ship options and `lib.mkDefault` defaults only; whoever imports them configures them |
| `package/` (currently only `home/package/`) |  | Nix package definitions for software **not in nixpkgs**, built with `pkgs.callPackage` (e.g. `home/package/unmined.nix`, `home/package/apps/swappy-shim.nix`) |

Two distinctions that decide where a file goes:

1. **`profiles/` = preconfigured, `modules/` = configurable.** `profiles/` holds ready-made
   values for a specific user; import it and it works. `modules/` is generic and reusable, with
   options and defaults but nothing hardcoded. The importing user supplies the values. A file under
   `modules/` that contains user-specific concrete values belongs in `profiles/` instead.
2. **`profiles/` and `modules/` are mirrored.** Both trees use the same relative structure in
   `home/` and `hosts/`. When you add something related, create the same relative path on the
   other side; never invent a new layout. Example: AI tooling lives at `terminal/ai/...` in both
   `home/modules/terminal/ai/` and `home/astroreen/profiles/terminal/ai/`.

---

## Repository structure

```
flake.nix                  # Root: nixosConfigurations + homeConfigurations, createHost helper
devenv.nix                 # Dev shell: nixos/home/nx/hm scripts, VPN helpers
overlays/                  # nixpkgs overlays: default.nix (aggregator), spotx.nix
hosts/
  astroreen/
    common/
      base/                # Headless settings for every host (nix, user, locale, network, ssh, tailscale, shell)
      desktop/             # Workstation layer (xserver, DM, audio, graphics, GUI nix-ld libs, steam, kitty)
    laptop/configuration.nix   # GRUB, Intel+NVIDIA PRIME offload, Docker, Plymouth
    pc/configuration.nix       # NVIDIA full, WoL, no sleep/suspend, Pi-hole, Ollama, Minecraft
    profiles/              # System-level profiles, preconfigured for astroreen
      apps/ lang/ style/ terminal/{shell,openvpn}/ wm/{hyprland,plasma}/
  modules/                 # Generic system modules (options/defaults only, no preconfigured values), currently empty
home/
  astroreen/
    common/
      base.nix             # Headless HM for every host (shell, devenv, ranger, opencode, claude, python, js)
      desktop.nix          # Workstation HM (hyprland/caelestia, GUI apps, kitty, dictation, java/csharp/flutter)
    laptop/home.nix        # Laptop HM overrides (monitor layout, caelestia)
    pc/home.nix            # PC HM overrides
    profiles/              # HM profiles, preconfigured for astroreen
      apps/ lang/ style/{cursor,theme}/ terminal/{ai,shell}/ wm/hyprland/
  modules/
    terminal/ai/           # AI tooling, see terminal/ai/AGENTS.md
    terminal/dictation/    # Push-to-talk dictation (faster-whisper server + socket daemon + Quickshell overlay)
  package/                 # Packages missing from nixpkgs, built with pkgs.callPackage (unmined.nix, apps/swappy-shim.nix, apps/t3code/)
  .opencode/                 # Local opencode plugin dev dir (package.json: @opencode-ai/plugin), not the config
scripts/sync-caelestia-config.py  # Caelestia config merge helper (devenv `sync-caelestia-config`)
```

---

## Host differences

| | laptop | pc |
|---|---|---|
| GPU | Intel (primary) + NVIDIA PRIME offload | NVIDIA only (nvidiaPersistenced=true for Ollama) |
| NVIDIA mode | Finegrained power mgmt, offload on demand | Always-on, full power |
| `nvidia-offload <cmd>` | Available for explicit GPU tasks | N/A |
| Sleep/suspend | Normal | Disabled (systemd targets off) |
| Wake-on-LAN | No | Yes (enp5s0, magic packet) |
| Extra services |  | Pi-hole (8573), Ollama (11434), faster-whisper (7777), KitchenOwl (9167), Minecraft (25565) |
| Docker NVIDIA | `nvidia-container-toolkit` | `enableNvidia = true` + toolkit |

Both use Lix (`nix.package = pkgs.lixPackageSets.stable.lix`) instead of stock Nix.

---

## AI tooling

AI tooling lives in two places:

| Task | File |
|------|------|
| Add MCP server | `home/modules/terminal/ai/mcps.nix`, add to `servers` attrset |
| Enable MCP per-host | host HM config, `programs.mcp.servers.<name>.disabled = false` |
| Add/edit opencode plugin config | `home/astroreen/profiles/terminal/ai/opencode/default.nix` (user-level profile, not under `modules/`) |
| Edit astrocode model/agent/fallback config | `home/astroreen/profiles/terminal/ai/opencode/astrocode.jsonc`, deployed to `~/.opencode/astrocode.jsonc` |
| Add agent definition | drop a frontmatter-free body `home/modules/terminal/ai/agents/<name>.md`, add its metadata to `agents/definitions.nix`, then list `<name>` in `custom.ai.agent.local.include` |
| Add slash command | drop a frontmatter-free body `home/modules/terminal/ai/commands/<name>.md`, add its metadata to `commands/definitions.nix`, then list `<name>` in `custom.ai.command.local.include` |
| Add bundled local skill | drop `home/modules/terminal/ai/skills/<name>/SKILL.md` (no frontmatter), add its metadata to `skills/definitions.nix`, then list `<name>` in `custom.ai.skill.local.include` |
| Tune an agent/command/skill (temperature, tools, model, ...) | profile: `custom.ai.{agent,command,skill}.definitions.<name>.<field>` (bundled values are per-field `mkDefault`) |
| Adopt an upstream skill | add its name to `custom.ai.skill.caveman.include` / `custom.ai.skill.matt-pocock.include` |
| Edit the global prompt | `home/astroreen/profiles/terminal/ai/CustomPrompt.md`, wired via `custom.ai.prompt` → opencode `AGENTS.md` + claude-code `CLAUDE.md` |
| Meridian proxy config | `home/modules/terminal/ai/meridian.nix`, `custom.ai.meridian.*`, port 3456, systemd user service |

- All MCPs are disabled by default (`lib.mkDefault true`); enable them per host
- opencode and claude-code are never wired directly: the `custom.ai.*` options declared under `home/modules/terminal/ai/` (`prompt` in `default.nix`, `agent`/`command`/`skill` in their own dirs) set `programs.opencode.*` / `programs.claude-code.*` themselves. profiles only pass the prompt (file or inline text) and pick names
- Every `*.local.include` is **empty = deploy nothing**; the upstream skill sets `caveman.include` / `matt-pocock.include` are **empty = copy all**. Skill sources are concatenated local → caveman → matt-pocock, so a later source wins a name collision (e.g. matt-pocock's `code-review` shadows the bundled one)
- Payloads land via home-manager `lndir`, so `~/.config/opencode/{agents,commands,skills}/` and `~/.claude/{agents,commands,skills}/` stay writable directories of read-only store symlinks — edit payloads in the repo, never in `$HOME`
- Payload `.md` files carry **no frontmatter**: the header is rendered per CLI from `custom.ai.{agent,command,skill}.definitions` by `home/modules/terminal/ai/lib.nix` (opencode forwards unknown agent fields to the provider, so the CLIs never share a header). `tools` uses opencode tool names and is translated for claude-code (agents: disabled → `disallowedTools`; commands/skills: enabled → `allowed-tools`); hex `color` is mapped to a claude named color; `temperature`/`mode` are opencode-only. CLI-specific fields go in `.opencode` / `.claude` (override generated ones, `null` removes), shared extras in `.extra`; `targets` limits an item to one CLI
- Agents and commands are passed as inline text to `programs.{opencode,claude-code}.{agents,commands}`; skills are built as one store dir per CLI (local skills get a regenerated SKILL.md, upstream ones are copied untouched)
- The activation installs Meridian via `npm install` (not a Nix package); nix-ld provides libsql support
- `custom.ai.prompt` (the `CustomPrompt.md` file) deploys as `~/.config/opencode/AGENTS.md` **and** `~/.claude/CLAUDE.md`, with the caveman always-on snippet appended when `custom.ai.skill.caveman.alwaysOn` is on; the astrocode plugin source is copied from the `inputs.astrocode` flake into `~/.config/opencode/plugins/.astrocode-src`
- A patch to the opencode core (`opencode-task-fallback.patch`) makes an aborted subagent wait for the fallback model instead of reporting "Task cancelled"
- The opencode web server runs headless on `0.0.0.0:4096` (`--mdns`) via user systemd `default.target`

---

## Code style

### Indentation and formatting
- 2-space indent, enforced by `nixfmt`
- Blank lines between logical sections; closing `}` on its own line

### Function args
```nix
{ pkgs, ... }:          # few args, one line
{                       # many args, multi-line
  config,
  pkgs,
  lib,
  ...
}:
_:                      # no args needed
```

### `with` usage
Only inside list literals, **never at file scope**:
```nix
environment.systemPackages = with pkgs; [ git curl wget ];  # correct
```
`with lib;` acceptable at top of `options = { ... }` blocks.

### `let-in`, imports, naming
- `let cfg = config.custom.<module>;` is the conventional alias
- Custom options: `custom.<name>` namespace
- Module files named after the program (`steam.nix`); aggregators named `default.nix` or `common-apps.nix`
- Pure data files (plain attrsets, no function args) imported directly via `import ./file.nix`
- Module files go in `imports = [ ... ]`; the module system handles arg passing

### `mkIf` / `mkDefault` / merging
- `config = lib.mkIf cfg.enable { ... }` wraps the entire config block
- `lib.mkDefault value` for host-overridable defaults
- `lib.recursiveUpdate` for deep merge; `//` for shallow
- Prefer native module merging over explicit `mkMerge`

### System vs HM module distinction
`hosts/astroreen/profiles/` sets `programs.*` (system), `services.*`, `environment.*`, `hardware.*`, `networking.*`, `virtualisation.*`
`home/astroreen/profiles/` sets `programs.*` (HM), `home.packages`, `home.file.*`, `home.activation.*`, `wayland.windowManager.*`

Some names exist in both with different semantics (e.g. `programs.zsh`).

---

## Do not touch

- `system.stateVersion` is `"25.11"` on both hosts (`hosts/astroreen/{laptop,pc}/configuration.nix`); never change it
- `home.stateVersion` is `"26.05"` (set once in `flake.nix` `createHost`, applies to both hosts); never change it. It intentionally differs from `system.stateVersion`; not a typo.
- `hardware-configuration.nix` is auto-generated; edit only if hardware changed
- `.devenv/`, `.direnv/` are build artifacts, gitignored
- Secrets (`*.age`, `*.ovpn`) are gitignored; never commit them

---

## Import chain

**System:**
```
flake.nix (createHost)
  → hosts/${username}/${host}/configuration.nix   (e.g. hosts/astroreen/laptop/configuration.nix)
    → ./hardware-configuration.nix
    → ../common/base                               (hosts/astroreen/common/base/default.nix)
        → nix-ld.nix (minimal libs), generic.nix, user.nix, language.nix, network.nix, certificates.nix
        → ../../profiles/terminal/{shell,tailscale.nix,ssh.nix}
    → ../common/desktop                            (laptop/pc only; hosts/astroreen/common/desktop/default.nix)
        → nix-ld.nix (GUI libs), packages.nix, network.nix (nm-applet, LocalSend/KDE Connect ports),
          services.nix, display-manager.nix, graphics.nix, audio.nix, fonts.nix, printing.nix
        → ../../profiles/apps/{steam,nautilus,wireshark}.nix, ../../profiles/terminal/{openvpn,shell/kitty.nix},
          ../../profiles/lang/flutter.nix
    → ../profiles/style/theme/dark/adwaita
    → ../profiles/wm/{hyprland,plasma}
```
Anything a headless host also needs goes in `common/base`; anything graphical goes in `common/desktop`.

`hosts/modules/` is currently empty.

**Home Manager:**
```
flake.nix (homeConfigurations."astroreen@<host>")
  → home/${username}/${host}/home.nix              (e.g. home/astroreen/laptop/home.nix)
    → ../common/base.nix
        → ../profiles/terminal/{shell,devenv.nix,ranger.nix}, ../profiles/terminal/ai/{opencode,claude}
        → ../profiles/lang/{javascript,python}.nix
    → ../common/desktop.nix                        (laptop/pc only)
        → ./hyprland/caelestia/default.nix
        → ../profiles/style/{cursor/breeze, theme/dark/adwaita}
        → ../profiles/apps/*  (apps, clipboard, screenshot, vesktop, vscode, obs, lutris,
          nautilus, gnome-text-editor, kdeconnect, vnc, tailscale, browser, music, minecraft, hyprmod, t3code)
        → ../profiles/terminal/{shell/kitty,wine,htop}.nix, ../profiles/terminal/ai/fabric
        → ../../modules/terminal/dictation           (faster-whisper server + socket PTT daemon + Quickshell overlay)
        → ../profiles/lang/{java,csharp,flutter}.nix
        → ../profiles/wm/hyprland/{default.nix, caelestia}
    → ./hyprland/settings.nix                      (host-specific Hyprland binds/monitors)
```
In `home/astroreen/pc/home.nix` only, also imports `../profiles/apps/arduino.nix` and
`../../modules/terminal/ai/lmstudio.nix` (the pc-only LMStudio package).

Reusable HM modules (not profiles), under `home/modules/`:
- `home/modules/terminal/ai/` holds MCP servers, the Meridian proxy, and the `custom.ai.{agent,command,skill}` payload dirs + options — the single place that wires opencode and claude-code.
- `home/modules/terminal/dictation/` has push-to-talk dictation: `server.py` (faster-whisper HTTP, port 7777,
  CUDA, model `faster-whisper-large-v3`), `daemon.py` (unix-socket PTT controller; also its own client via
  `dictation-daemon start|stop|toggle|status`), `overlay/` (standalone Quickshell `qs -c dictation-overlay`).
  WM-agnostic; imported from `home/astroreen/common/desktop.nix`. The Hyprland hold-to-talk binds live in
  `home/astroreen/common/hyprland/caelestia/default.nix` (`SUPER + F9` toggles: press to start, press again to stop/transcribe).
  PC sets `custom.dictation.host = "0.0.0.0"` to expose the transcription server on the LAN/tailnet.

**Dormant / unimported** (exist but not referenced in `home/astroreen/common/{base,desktop}.nix` or any host `home.nix`):
- `home/astroreen/profiles/apps/blender.nix`
- `home/astroreen/profiles/terminal/ssh.nix`
- `home/astroreen/profiles/terminal/ollama.nix`
- `home/astroreen/profiles/terminal/whisper.nix`

---

## Key facts

- `nixpkgs.config.allowUnfree = true` and `android_sdk.accept_license = true` are set in the flake, not per-host
- Hyprland comes from the upstream flake input (`inputs.hyprland`), not nixpkgs; the cachix cache depends on that
- Hyprland uses Lua config (`configType = "lua"`), not `hyprland.conf`. Settings are attrsets with `_args` + `lib.generators.mkLuaInline` dispatchers. Base binds live in `home/astroreen/profiles/wm/hyprland/settings/binds.nix`; host overrides in `home/astroreen/{laptop,pc}/hyprland/settings.nix`
- `nix-ld` is enabled on both hosts so prebuilt ELF binaries run without patching
- No automated test suite; validate with `dry-build` / `dry-activate`
- The `caelestia-shell` config is written via `home.activation` (not symlinked); the shell mutates it at runtime
- Opencode alias: `oc = "opencode"`
- Opencode theme: `gruvbox`; plugins: md-table-formatter, notifier, dcp (context compression), vibeguard, anthropic-auth, claude-auth
- `inputs.caveman` (flake=false) is a plain source tree for the caveman opencode skill
- `nixpkgs-stable` (`nixos-25.11`) is available as `pkgs-stable` in all module specialArgs
