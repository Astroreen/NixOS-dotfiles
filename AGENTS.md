# AGENTS.md — NixOS Configuration Repository

NixOS flake-based dotfiles. Two hosts (`laptop`, `server`), user `astroreen`. Home-manager embedded in NixOS via `home-manager.nixosModules.home-manager` (not standalone).

---

## Build Commands

All scripts run inside the `devenv` shell (auto-activated via `.envrc` + direnv).

### NixOS — `nixos <action> <host>` (alias: `nx`)

```bash
nixos dry-build laptop      # Evaluate + show store paths — no side effects
nixos dry-activate laptop   # Show what activation would do — no side effects
nixos test laptop           # Build + activate, no bootloader entry (safe)
nixos switch laptop         # Build + activate + bootloader entry
nixos build laptop          # Build only, no activation
nixos rollback laptop       # Roll back to previous generation
```

Replace `laptop` with `server` for server. **Always `dry-build` before applying.**

Every `nixos` call runs `git add .` first — unstaged changes are invisible to nixos-rebuild.
Every `nixos` call uses `sudo` after `git add .` — some changes require sudo priveleges.

### Home Manager — `home <action> <host>` (alias: `hm`)

```bash
home switch laptop          # Build + activate HM config
home build laptop           # Build only
home rollback laptop        # Roll back HM generation
```

HM configs are `homeConfigurations."astroreen@<host>"` in the flake — managed independently from the NixOS system.

### Other

```bash
update-flake                # nix flake update
delete-garbage              # nix-collect-garbage --delete-older-than 7d + nix-store --gc
start-whisper               # whisper-server on port 7777 (medium model)
start-work / end-work       # OpenVPN + DNS setup/teardown for work
add-work-dns / delete-work-dns  # DNS only (no VPN start/stop)
```

### Linting / Formatting

```bash
statix check .              # Static analysis: antipatterns, deprecated options
statix fix .                # Auto-fix statix warnings
deadnix .                   # Find unused bindings/args
deadnix --edit .            # Auto-remove dead code
nixfmt <file>.nix           # Format single file (2-space indent)
```

---

## Repository Structure

```
flake.nix                  # Root: nixosConfigurations + homeConfigurations, createHost helper
devenv.nix                 # Dev shell: nixos/home/nx/hm scripts, VPN helpers, start-whisper
overlays/                  # nixpkgs overlays (default.nix aggregator)
hosts/                     # NixOS system-level modules
  common-settings.nix      # Shared: timezone, locale, nix GC, fonts
  common-services.nix      # Shared: audio, display manager, printing
  common-apps.nix          # Shared: steam, nautilus, wireshark, gns3, tailscale, ssh, flutter
  certificates.nix         # Corporate PKI (inline PEM)
  nix-ld.nix               # nix-ld + library list for prebuilt ELF binaries
  laptop/                  # GRUB, Intel+NVIDIA PRIME offload, Docker, Plymouth
  server/                  # NVIDIA full, WoL, no sleep/suspend, Pi-hole, Ollama, Minecraft
  modules/                 # System modules: gui/, tui/, lang/, style/, wm/
home/                      # Home-manager configuration
  common-apps.nix          # Shared HM: gui apps, kitty, shell, AI tools, languages
  astroreen/common/        # Shared HM config (hyprland, shell, AI tools)
  astroreen/laptop/        # Laptop HM overrides (monitor layout, caelestia)
  astroreen/server/        # Server HM overrides
  modules/                 # HM modules: gui/, tui/, lang/, style/, wm/
    tui/ai/                # AI tooling — see tui/ai/AGENTS.md for details
scripts/                   # Shell scripts: Hyprland monitor hotplug/layout
.opencode/opencode.json    # OpenCode plugin config (oh-my-opencode)
```

---

## Host Differences

| | laptop | server |
|---|---|---|
| GPU | Intel (primary) + NVIDIA PRIME offload | NVIDIA only (nvidiaPersistenced=true for Ollama) |
| NVIDIA mode | Finegrained power mgmt, offload on demand | Always-on, full power |
| `nvidia-offload <cmd>` | Available for explicit GPU tasks | N/A |
| Sleep/suspend | Normal | Disabled (systemd targets off) |
| Wake-on-LAN | No | Yes (enp5s0, magic packet) |
| Extra services | — | Pi-hole (8573), Ollama (11434), Whisper (7777), KitchenOwl (9167), Minecraft (25565) |
| Docker NVIDIA | `nvidia-container-toolkit` | `enableNvidia = true` + toolkit |

Both use Lix (`nix.package = pkgs.lixPackageSets.stable.lix`) instead of stock Nix.

---

## AI Tooling (home/modules/tui/ai/)

See `home/modules/tui/ai/AGENTS.md` for the authoritative reference. Quick index:

| Task | File |
|------|------|
| Add MCP server | `mcps.nix` — add to `servers` attrset |
| Enable MCP per-host | host HM config — `programs.mcp.servers.<name>.disabled = false` |
| Add opencode plugin | `opencode/default.nix` — `programs.opencode.settings.plugin` |
| Add agent definition | `agents/` — `.md` file, deployed via `home.activation` |
| Add slash command | `commands/` — `.md` file, deployed via `home.activation` |
| Meridian proxy config | `meridian.nix` — port 3456, systemd user service |

- All MCPs disabled by default (`lib.mkDefault true`) — opt-in per-host
- Opencode config deployed via `home.activation` copy (chmod 777), **not symlinked** — files must stay mutable
- Meridian installed via `npm install` in activation (not a Nix package); nix-ld provides libsql support

---

## Code Style

### Indentation / formatting
- 2-space indent, enforced by `nixfmt`
- Blank lines between logical sections; closing `}` on its own line

### Function args
```nix
{ pkgs, ... }:          # few args — one line
{                       # many args — multi-line
  config,
  pkgs,
  lib,
  ...
}:
_:                      # no args needed
```

### `with` usage
Only inside list literals — **never at file scope**:
```nix
environment.systemPackages = with pkgs; [ git curl wget ];  # correct
```
`with lib;` acceptable at top of `options = { ... }` blocks.
Two legacy file-scope violations exist — do not add more, fix when touching those files.

### `let-in`, imports, naming
- `let cfg = config.custom.<module>;` is the conventional alias
- Custom options: `custom.<name>` namespace
- Module files named after the program (`steam.nix`); aggregators named `default.nix` or `common-apps.nix`
- Pure data files (plain attrsets, no function args) imported directly via `import ./file.nix`
- Module files go in `imports = [ ... ]` — the module system handles arg passing

### `mkIf` / `mkDefault` / merging
- `config = lib.mkIf cfg.enable { ... }` — wrap entire config block
- `lib.mkDefault value` for host-overridable defaults
- `lib.recursiveUpdate` for deep merge; `//` for shallow
- Prefer native module merging over explicit `mkMerge`

### System vs HM module distinction
`hosts/modules/` — sets `programs.*` (system), `services.*`, `environment.*`, `hardware.*`, `networking.*`, `virtualisation.*`
`home/modules/` — sets `programs.*` (HM), `home.packages`, `home.file.*`, `home.activation.*`, `wayland.windowManager.*`

Some names exist in both with different semantics (e.g. `programs.zsh`).

---

## Do Not Touch

- `system.stateVersion` and `home.stateVersion` — `"25.11"` on both hosts; never change
- `hardware-configuration.nix` — auto-generated; edit only if hardware changed
- `.devenv/`, `.direnv/` — build artifacts, gitignored
- Secrets (`*.age`, `*.ovpn`) — gitignored, never commit

---

## Import Chain

**System:**
```
flake.nix (createHost)
  → hosts/{laptop,server}/configuration.nix
    → hosts/common-{settings,services,apps}.nix
    → hosts/certificates.nix, nix-ld.nix
    → hosts/modules/{gui,tui,lang,style,wm}/*
```

**Home Manager:**
```
flake.nix (homeConfigurations."astroreen@<host>")
  → home/astroreen/{laptop,server}/home.nix
    → home/astroreen/common/home.nix
      → home/common-apps.nix
        → home/modules/{gui,tui,lang,style,wm}/*
```

**Dormant / unimported** (do not import):
- `home/modules/gui/blender.nix`
- `home/modules/tui/ssh.nix`

---

## Key Facts

- `nixpkgs.config.allowUnfree = true` + `android_sdk.accept_license = true` — set in flake, not per-host
- Hyprland from upstream flake input (`inputs.hyprland`), not nixpkgs — required for cachix cache correctness
- `nix-ld` enabled on both hosts — prebuilt ELF binaries run without patching
- No automated test suite — validation is `dry-build` / `dry-activate`
- `caelestia-shell` config written via `home.activation` (not symlinked) — shell mutates it at runtime
- Opencode alias: `oc = "opencode"`
- Opencode theme: `gruvbox`; plugins include vibeguard, dcp (context compression), md-table-formatter
- `inputs.caveman` (flake=false) is a plain source tree for the caveman opencode skill
- `nixpkgs-stable` (`nixos-25.11`) available as `pkgs-stable` in all module specialArgs
