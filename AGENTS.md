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
overlays/                  # nixpkgs overlays: default.nix (aggregator), spotx.nix
hosts/
  astroreen/
    common/                # Shared system settings (was hosts/common-*.nix, certificates.nix, nix-ld.nix pre-reorg)
    laptop/configuration.nix   # GRUB, Intel+NVIDIA PRIME offload, Docker, Plymouth
    server/configuration.nix   # NVIDIA full, WoL, no sleep/suspend, Pi-hole, Ollama, Minecraft
    profiles/              # System-level profiles (replaces old hosts/modules/{gui,tui,lang,style,wm} split)
      apps/ lang/ style/ terminal/{shell,openvpn}/ wm/{hyprland,plasma}/
  modules/                 # Legacy system module dir — mostly superseded by hosts/astroreen/profiles/
home/
  astroreen/
    common/                # Shared HM config (hyprland/caelestia, assets)
    laptop/home.nix        # Laptop HM overrides (monitor layout, caelestia)
    server/home.nix        # Server HM overrides
    profiles/              # HM profiles (replaces old home/modules/{gui,tui,lang,style,wm} split)
      apps/ lang/ style/{cursor,theme}/ terminal/{ai,shell}/ wm/hyprland/
  modules/
    terminal/ai/           # AI tooling (moved from modules/tui/ai) — see terminal/ai/AGENTS.md
.opencode/opencode.json    # OpenCode plugin config (oh-my-opencode)
```

> **2026-07 reorg note**: `hosts/modules/{gui,tui,lang,style,wm}` and `home/modules/{gui,tui,lang,style,wm}`
> were replaced by `hosts/astroreen/profiles/*` and `home/astroreen/profiles/*`. Host/home entry files also
> moved under the username: `hosts/${username}/${host}/configuration.nix`, `home/${username}/${host}/home.nix`
> (see `flake.nix` `createHost`). `home/modules/` now holds only `terminal/ai/`.

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

## AI Tooling

Split across two locations — see `home/modules/terminal/ai/AGENTS.md` for the module reference:

| Task | File |
|------|------|
| Add MCP server | `home/modules/terminal/ai/mcps.nix` — add to `servers` attrset |
| Enable MCP per-host | host HM config — `programs.mcp.servers.<name>.disabled = false` |
| Add/edit opencode plugin config | `home/astroreen/profiles/terminal/ai/opencode/default.nix` (user-level profile, NOT under `modules/`) |
| Add agent definition | `home/astroreen/profiles/terminal/ai/agents/` — `.md` file |
| Add slash command | `home/modules/terminal/ai/commands/` — `.md` file |
| Add/edit skill (learn, caveman) | `home/modules/terminal/ai/skills/` — toggled via `custom.ai.skill.{learn,caveman}.enable` |
| Meridian proxy config | `home/modules/terminal/ai/meridian.nix` — `custom.ai.meridian.*`, port 3456, systemd user service |

- All MCPs disabled by default (`lib.mkDefault true`) — opt-in per-host
- Skill/agent files deployed via `home.activation` copy (chmod 777), **not symlinked** — files must stay mutable
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
No current file-scope `with` violations found (previously-noted legacy violations have been cleaned up).

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

- `system.stateVersion` — `"25.11"` on both hosts (`hosts/astroreen/{laptop,server}/configuration.nix`); never change
- `home.stateVersion` — `"26.05"` (set once in `flake.nix` `createHost`, applies to both hosts); never change. Note: intentionally differs from `system.stateVersion` — not a typo.
- `hardware-configuration.nix` — auto-generated; edit only if hardware changed
- `.devenv/`, `.direnv/` — build artifacts, gitignored
- Secrets (`*.age`, `*.ovpn`) — gitignored, never commit

---

## Import Chain

**System:**
```
flake.nix (createHost)
  → hosts/${username}/${host}/configuration.nix   (e.g. hosts/astroreen/laptop/configuration.nix)
    → ./hardware-configuration.nix
    → ../common                                    (hosts/astroreen/common/default.nix)
        → nix-ld.nix, generic.nix, user.nix, language.nix, services.nix, network.nix,
          display-manager.nix, graphics.nix, audio.nix, fonts.nix, certificates.nix, printing.nix
    → ../profiles/style/theme/dark/adwaita
    → ../profiles/wm/{hyprland,plasma}
    → ../profiles/apps/*, ../profiles/terminal/{shell,openvpn,ssh,tailscale}.nix, ../profiles/lang/flutter.nix
```
`hosts/modules/` is currently empty — fully superseded by `hosts/astroreen/profiles/`.

**Home Manager:**
```
flake.nix (homeConfigurations."astroreen@<host>")
  → home/${username}/${host}/home.nix              (e.g. home/astroreen/laptop/home.nix)
    → ../common/home.nix
        → ./hyprland/caelestia/default.nix
        → ../profiles/style/{cursor/breeze, theme/dark/adwaita}
        → ./imports.nix
            → ../profiles/apps/*  (16 files, e.g. apps, clipboard, vesktop, vscode, obs, lutris,
              nautilus, kdeconnect, vnc, tailscale, browser, music, minecraft)
            → ../profiles/terminal/{wine,shell,htop,devenv,ranger}.nix
            → ../profiles/terminal/ai/{fabric,opencode,claude}
            → ../profiles/lang/{java,javascript,csharp,python,flutter}.nix
        → ../profiles/wm/hyprland/{default.nix, caelestia}
    → ./hyprland/settings.nix                      (host-specific Hyprland binds/monitors)
```
(server only, in `home/astroreen/server/home.nix`): also imports `../profiles/apps/arduino.nix`,
`../profiles/terminal/whisper.nix`, and `../../modules/terminal/ai/lmstudio.nix` directly (server-only LMStudio package).

Reusable HM module (not a profile): `home/modules/terminal/ai/` — imported separately, provides
MCP servers, Meridian proxy, skills/commands infra (see AI Tooling section above).

**Dormant / unimported** (exist but not referenced in `home/astroreen/common/imports.nix` or any host `home.nix`):
- `home/astroreen/profiles/apps/blender.nix`
- `home/astroreen/profiles/terminal/ssh.nix`

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
