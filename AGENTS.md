# AGENTS.md — NixOS Configuration Repository

This is a NixOS flake-based dotfiles repository managing two hosts (`laptop`, `server`) for user `astroreen`, using home-manager embedded inside NixOS configurations.

---

## Build, Lint, and Validation Commands

All scripts below are available inside the `devenv` shell (auto-activated via `.envrc` + direnv).

### Validation (run before applying)

```bash
dry-build-laptop       # Show what store paths would be built — no side effects
dry-build-server
dry-activate-laptop    # Show what activation scripts would do — no side effects
dry-activate-server
```

**Always run `dry-build-<host>` before applying changes to catch evaluation errors.**

### Applying configuration

```bash
test-laptop            # Build + activate, no bootloader entry (safe for testing)
test-server
switch-laptop          # Build + activate + add bootloader entry
switch-server
```

### Build only (no activation)

```bash
build-laptop
build-server
```

### Other operations

```bash
update-flake           # Update flake.lock
rollback-laptop        # Rollback to previous generation
rollback-server
delete-garbage         # nix-collect-garbage --delete-older-than 7d && nix-store --gc
```

### devenv tasks (ordered pipelines)

```bash
devenv tasks run nixos:switch-laptop   # update-flake → switch-laptop → delete-garbage
devenv tasks run nixos:switch-server
```

### Linting

```bash
statix check .         # Static analysis: antipatterns, deprecated options
statix fix .           # Auto-fix statix warnings
deadnix .              # Find unused bindings and arguments
deadnix --edit .       # Auto-remove dead code
```

### Formatting

```bash
nixfmt <file>.nix      # Format a single file (tab size 2)
```

### Important: unstaged changes are invisible to nixos-rebuild

Every rebuild script already runs `git add .` first. If calling `nixos-rebuild` manually, stage changes first:

```bash
git add . && sudo nixos-rebuild dry-build --flake .#laptop
```

---

## Repository Structure

```
flake.nix                  # Root flake — only nixosConfigurations.{laptop,server}
devenv.nix                 # Dev shell: scripts, tasks, env vars
overlays/                  # nixpkgs overlays (default.nix aggregator + per-overlay files)
hosts/                     # NixOS system-level modules
  common-settings.nix      # Shared: timezone, locale, nix GC, fonts
  common-services.nix      # Shared: audio, display manager, printing
  common-apps.nix          # Shared: imports all hosts/modules/*
  certificates.nix         # Corporate PKI (inline PEM)
  nix-ld.nix               # nix-ld with library list for prebuilt binaries
  laptop/                  # Laptop-specific: GRUB, NVIDIA prime, docker
  server/                  # Server-specific: WoL, Ollama, no sleep
  modules/                 # System modules: gui/, tui/, lang/, style/, wm/
home/                      # Home-manager configuration
  common-apps.nix          # Shared HM imports
  astroreen/common/        # Shared HM config (hyprland, shell, AI tools…)
  astroreen/laptop/        # Laptop HM overrides (monitor, caelestia)
  astroreen/server/        # Server HM overrides
  modules/                 # HM modules: gui/, tui/, lang/, style/, wm/
scripts/                   # Shell scripts (monitor management, hyprland wrapper)
.opencode/opencode.json    # OpenCode plugin config (oh-my-opencode)
```

---

## Code Style Guidelines

### Indentation and formatting

- 2-space indentation throughout — enforced by `nixfmt`
- Blank lines between logical sections within a file
- Closing brackets on their own line for multi-line attribute sets

### Function argument style

Single or few args — one line:
```nix
{ pkgs, ... }:
```

Many args — multi-line block:
```nix
{
  config,
  pkgs,
  lib,
  ...
}:
```

File with no needed args:
```nix
_:
```

### `let-in` usage

Use `let-in` at file scope to define local helpers, computed values, or imported sub-configs:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.myFeature;
  mySettings = import ./settings.nix;
in
{
  # ...
}
```

### `with` usage

Only inside list literals — never at file scope:

```nix
# Correct
environment.systemPackages = with pkgs; [ git curl wget ];

# Wrong — do not use with pkgs; at file scope
```

`with lib;` is acceptable at the top of `options = { ... }` blocks.

### Import patterns

Pure data files (returning plain attrsets, no function args) are imported directly:
```nix
# settings.nix is just: { option = value; }
let settings = import ./settings.nix;
```

Module files (needing `pkgs`, `lib`, `config`) go in the `imports` list — the module system handles arg passing:
```nix
imports = [
  ./steam.nix
  ./tailscale.nix
  inputs.hyprland.nixosModules.default
];
```

### Naming conventions

- Custom options live under the `custom.<name>` namespace: `custom.caelestia.enable`, `custom.caelestia.settings`
- Module files are named after the program/service they configure (`steam.nix`, `tailscale.nix`)
- Aggregator modules that only import others are named `default.nix` or `common-apps.nix`
- Pure data files use descriptive names: `settings.nix`, `animations.nix`, `binds.nix`
- `cfg = config.custom.<module>` is the conventional alias for the module's own config

### Declaring custom options

```nix
{ pkgs, lib, config, ... }:
let
  cfg = config.custom.myFeature;
in
{
  options = with lib; {
    custom.myFeature = {
      enable = mkEnableOption "description of the feature";
      someOption = mkOption {
        type = types.str;
        default = "";
        description = "What this option does";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # actual settings
  };
}
```

### `mkIf`, `mkDefault`, `mkMerge`

- Wrap the entire `config` block with `lib.mkIf cfg.enable { ... }` in conditional modules
- Use `lib.mkDefault value` for values that host-specific configs should be able to override
- Use `lib.recursiveUpdate base override` for deep-merging attrsets
- Use `//` for shallow attrset merges
- Prefer the NixOS module system's native merging (via multiple `imports`) over explicit `mkMerge`

### System vs Home-manager module distinction

`hosts/modules/` — NixOS system modules; set:
- `programs.*` (system-level), `services.*`, `environment.*`
- `hardware.*`, `security.*`, `networking.*`, `virtualisation.*`

`home/modules/` — Home Manager modules; set:
- `programs.*` (HM namespace), `home.packages`, `home.sessionVariables`
- `home.file.*`, `home.activation.*`
- `wayland.windowManager.*`, `dconf.*`, `gtk.*`

Some program names exist in both layers with different semantics (e.g. `programs.zsh` system = enable the shell; HM = full config with plugins, aliases, etc.).

### File organization

- One concern per file (`steam.nix` only configures Steam)
- Multi-file modules use a `default.nix` as entry point
- Host-specific overrides are minimal — bulk config goes in `common/`
- Pure data (keybinds, animation curves, VSCode settings) lives in separate plain-attrset files

---

## Do Not Touch

- `system.stateVersion` and `home.stateVersion` — currently `"25.11"` on both hosts; never change
- `hardware-configuration.nix` files — auto-generated from hardware scan; edit only if hardware changed
- `.devenv/`, `.direnv/` — build artifacts, gitignored
- Any secrets files (`*.age`, `*.ovpn`) — gitignored and never committed

---

## Key Facts for Agents

- Both hosts use the same username `astroreen`
- `nixpkgs.config.allowUnfree = true` is set — unfree packages are allowed
- Hyprland comes from the upstream flake input (`inputs.hyprland`), not nixpkgs — necessary for cachix binary cache correctness
- `nix-ld` is enabled on both hosts — prebuilt ELF binaries run without patching
- There is no automated test suite — validation is `dry-build` / `dry-activate` before switching
- The `caelestia-shell` config is written via `home.activation` (not symlinked) so the shell can mutate it at runtime
- `home-manager` is embedded in NixOS configs via `home-manager.nixosModules.home-manager`, not a standalone `home-manager switch`
