# AGENTS.md: NixOS configuration repository

NixOS flake-based dotfiles. Four hosts (`laptop`, `pc`, headless servers `aktkc` and `hercules`), user `astroreen`. Home-manager embedded in NixOS via `home-manager.nixosModules.home-manager` (not standalone).

---

## Build commands

Two rules agents get wrong constantly. Read both before running anything:

1. **Host**: never hardcode `laptop`, `pc`, `aktkc` or `hercules`. The machine you are on RIGHT NOW is the deploy
   target. Determine it with `hostname -s`; its output is exactly the flake host name (`laptop`, `pc`, `aktkc` or `hercules`).
2. **devenv**: scripts (`nixos`, `home`, `nx`, `hm`, `update-flake`, ...) exist ONLY inside the
   `devenv` shell. Interactive `.envrc`/direnv auto-activation does NOT apply to agent/SSH bash
   sessions. Wrap every call as `devenv shell -- <command>`. Run from the repo root.

### Host selection

```bash
hostname -s    # "laptop", "pc", "aktkc" or "hercules"; use this as <host> in every command below
```

Use `"$(hostname -s)"` substitution, never a literal host name copied from examples. If the output
is not `laptop`, `pc`, `aktkc` or `hercules`, stop and ask the user which flake host to target.

- `switch` / `test` / `rollback` / `dry-activate` ALWAYS target the current machine (`"$(hostname -s)"`).
- `build` / `dry-build` for the OTHER host only when the user explicitly names that host.
- The one exception: `deploy` / `bootstrap` (below) push to a remote host, and only when the user
  explicitly asks to deploy or install that host.

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

### Remote server hosts (`aktkc`, `hercules`)

```bash
devenv shell -- deploy <action> <host>                      # nixos-rebuild --target-host (switch/test/boot/dry-activate); on switch also copies + activates astroreen's HM
devenv shell -- bootstrap <host> root@<ip> [authkey-file]   # nixos-anywhere fresh install: WIPES the disk set in disko.devices.disk.main.device
```

`bootstrap` refuses to run while `hosts/astroreen/common/server/authorized_keys` has no key (password SSH is
off), regenerates `hardware-configuration.nix`, and copies the optional Tailscale auth key to
`/var/lib/tailscale/authkey` for unattended tailnet login. The `agent` account's HM is applied by the
system itself (`home-manager.users.agent`), so `deploy` covers it.

### Other

```bash
devenv shell -- update-flake                # nix flake update
devenv shell -- delete-garbage              # nix-collect-garbage --delete-older-than 7d + nix-store --gc
devenv shell -- start-work                  # OpenVPN + DNS setup for work
devenv shell -- stop-work                   # OpenVPN + DNS teardown
devenv shell -- add-work-dns                # DNS only (no VPN start)
devenv shell -- delete-work-dns             # DNS only (no VPN stop)
devenv shell -- sync-caelestia-config       # Merge official caelestia example config into host JSONs (scripts/sync-caelestia-config.py)
devenv shell -- sync-dux-config [host]      # Copy live ~/.config/dms/settings.json into home/astroreen/<host>/assets/dux-settings.json (default: hostname -s)
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
      server/              # Server/VPS layer (disko, hybrid BIOS+UEFI GRUB, disk auto-grow, firewall, authorized_keys, agent HM, no sleep)
    laptop/configuration.nix   # GRUB, Intel+NVIDIA PRIME offload, Docker, Plymouth
    pc/configuration.nix       # NVIDIA full, WoL, no sleep/suspend, Ollama, Minecraft
    aktkc/                     # VMware VM server (BIOS, /dev/sda): configuration.nix (hostName, disk, extra services), github-runners.nix (Caspian ERP CI), hardware config
    hercules/                  # Bare-metal home server (Z790, i7-14700KF, RTX 4080 SUPER; NixOS on the 980 PRO NVMe): configuration.nix, nvidia.nix (headless driver, container toolkit, docker enableNvidia for Nextcloud AIO), hardware config, /mnt/nextcloud_storage (4TB USB, nofail)
    profiles/              # System-level profiles, preconfigured for astroreen
      apps/ lang/ style/ terminal/{shell,openvpn}/ wm/{hyprland,plasma}/
      server/              # services/ (Docker services, preconfigured for hercules), hardening, agent account, containers, restic backup (dormant, import commented out in common/server), uptime-kuma (per host)
  modules/                 # Generic system modules (options/defaults only, no preconfigured values)
    server/services/       # custom.services.<name>: Docker services (actual, cloudflared, n8n, nextcloud-aio, pihole, vaultwarden) on one shared network (custom.services.network); custom.services.lan closes published ports on LAN interfaces (DOCKER-USER)
home/
  astroreen/
    common/
      base.nix             # Headless HM for every host (shell, devenv, ranger, opencode, claude, python, js)
      desktop.nix          # Workstation HM (hyprland, caelestia or dux shell, GUI apps, kitty, dictation, java/csharp/flutter)
      server.nix           # Server HM: base.nix + T3 Code with `t3 serve` user service (0.0.0.0:3773)
      agent.nix            # HM for the `agent` account on server hosts, applied via the NixOS home-manager module
    laptop/home.nix        # Laptop HM overrides (monitor layout, caelestia; dux settings ready for the switch)
    pc/home.nix            # PC HM overrides
    aktkc/home.nix         # aktkc HM (common/server.nix only)
    hercules/home.nix      # hercules HM (common/server.nix + astro-dashboard.nix, moved from aktkc)
    profiles/              # HM profiles, preconfigured for astroreen
      apps/ lang/ style/{cursor,theme}/ terminal/{ai,shell}/ wm/{hyprland,keybinds,shell}/
  modules/
    terminal/ai/           # AI tooling, see terminal/ai/AGENTS.md
    wm/keybinds/           # custom.keybinds: WM-agnostic named binds + Hyprland backend
    wm/shell/              # custom.caelestia / custom.dux shell modules (at most one enabled)
    terminal/dictation/    # Push-to-talk dictation (faster-whisper server + socket daemon + Quickshell overlay)
  package/                 # Packages missing from nixpkgs, built with pkgs.callPackage (unmined.nix, apps/swappy-shim.nix, apps/t3code/)
  .opencode/                 # Local opencode plugin dev dir (package.json: @opencode-ai/plugin), not the config
scripts/sync-caelestia-config.py  # Caelestia config merge helper (devenv `sync-caelestia-config`)
```

---

## Host differences

| | laptop | pc | aktkc | hercules |
|---|---|---|---|---|
| Layers | base + desktop | base + desktop | base + server (headless) | base + server (headless) |
| GPU | Intel (primary) + NVIDIA PRIME offload | NVIDIA only (nvidiaPersistenced=true for Ollama) | None | RTX 4080 SUPER, open kernel modules, headless (`nvidia.nix`) |
| NVIDIA mode | Finegrained power mgmt, offload on demand | Always-on, full power | N/A | Compute only, nvidiaPersistenced |
| `nvidia-offload <cmd>` | Available for explicit GPU tasks | N/A | N/A | N/A |
| Sleep/suspend | Normal | Disabled (systemd targets off) | Disabled | Disabled |
| Wake-on-LAN | No | Yes (enp5s0, magic packet) | No | No |
| Extra services |  | Ollama (11434), faster-whisper (7777), KitchenOwl (9167), Minecraft (25565) | Uptime Kuma (3001), Docker, rootless podman, T3 Code server (3773), GitHub runners for Caspian ERP | Uptime Kuma (3001), Docker, rootless podman, T3 Code server (3773), astro-dashboard (8889, user service), Docker services from `profiles/server/services`: Vaultwarden (8812), Pi-hole (53, 8573), n8n (5678), Actual (5006), Nextcloud AIO (8080 interface, Apache 11000), cloudflared |
| Docker NVIDIA | `nvidia-container-toolkit` | `enableNvidia = true` + toolkit | N/A | `enableNvidia = true` + toolkit (AIO needs the legacy `--gpus` path) |
| Network exposure | Normal | LAN ports for its services | Tailnet only (`tailscale0` trusted), plus key-only SSH (22) on all interfaces | Tailnet + Cloudflare Tunnel (cloudflared on `cloudflare_network`); from the LAN (`enp4s0`, 192.168.50.192) only SSH and Pi-hole DNS (53); Tailscale exit node, host DNS = Pi-hole (127.0.0.1) so exit-node clients are filtered too |
| Deploy | Local `nixos`/`home` | Local `nixos`/`home` | Remote `deploy`, first install via `bootstrap` | Remote `deploy`, first install via `bootstrap` |

Server accounts: `astroreen` (wheel, passwordless sudo, docker, lingering for the T3 user service) and `agent` (no wheel/docker, lingering,
rootless podman) for autonomous agents. Restic backups (`profiles/server/backup.nix`) are disabled until a
backup target exists; when enabled, they read the repository URL and password from
`/etc/restic/{repository,password}`, created by hand on the host (not in the repo).

aktkc runs the Caspian ERP GitHub Actions runners (`hosts/astroreen/aktkc/github-runners.nix`: `caspian-ci` ×3,
`caspian-e2e`, `caspian-pipeline`) as `astroreen`, with HOME and work dirs under `/var/lib/caspian-ci`.
The registration token lives in `/var/lib/secrets/github-runner-caspian` (by hand, not in the repo; the
command is in the file header). The Playwright Chromium libraries are added to `programs.nix-ld.libraries` there.

All hosts use Lix (`nix.package = pkgs.lixPackageSets.stable.lix`) instead of stock Nix.

---

## AI tooling

AI tooling lives in two places:

| Task | File |
|------|------|
| Add MCP server | `home/modules/terminal/ai/mcps.nix`, add to `servers` attrset |
| Enable MCP per-host | host HM config, `programs.mcp.servers.<name>.disabled = false` |
| Pick agents/commands/skills for both CLIs | `home/astroreen/profiles/terminal/ai/payload.nix` (`custom.ai.{agent,command,skill}.*.include`) |
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
- opencode and claude-code are never wired directly: the `custom.ai.*` options declared under `home/modules/terminal/ai/` (`prompt` in `default.nix`, `agent`/`command`/`skill` in their own dirs) set `programs.opencode.*` / `programs.claude-code.*` themselves. The prompt and the picked names live in `home/astroreen/profiles/terminal/ai/payload.nix`, imported by both the opencode and claude profiles, so both CLIs always get the same set
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

- `system.stateVersion` is `"25.11"` on laptop/pc and `"26.11"` on aktkc and hercules (`hosts/astroreen/<host>/configuration.nix`); never change it
- `home.stateVersion` is `"26.05"` (set once in `flake.nix` `createHost`, applies to all hosts); never change it. It intentionally differs from `system.stateVersion`; not a typo.
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
Anything a headless host also needs goes in `common/base`; anything graphical goes in `common/desktop`;
anything every server/VPS needs goes in `common/server`.

Server hosts (`aktkc`, `hercules`) import `./hardware-configuration.nix`, `../common/base`, `../common/server`
(→ `./disko.nix`, `../../profiles/server/{hardening,agent,containers}.nix`) plus per-host
profiles (`../profiles/server/monitoring.nix`) and own files (`./github-runners.nix` on aktkc, `./nvidia.nix` on hercules). Each sets `networking.hostName`,
`disko.devices.disk.main.device` and `system.stateVersion`. Their flake entry uses
`extraModules = serverModules` (`inputs.disko.nixosModules.disko` + `home-manager.nixosModules.home-manager` for `agent`).
New server/VPS: add `hosts/astroreen/<host>/configuration.nix`, `home/astroreen/<host>/home.nix`
(imports `../common/server.nix`), a `hosts` entry in `flake.nix`, then `bootstrap <host> root@<ip>`.

`hosts/modules/server/services/` holds the Docker service modules (`custom.services.<name>`); their preconfigured values are in
`hosts/astroreen/profiles/server/services/` (imported by hercules), secrets in `/var/lib/secrets/<name>.env` on the host (by hand,
not in the repo). State lives in `/var/lib/<name>` (root-only, 0700); Nextcloud AIO keeps its own `nextcloud_aio_*` Docker volumes.
The AIO mastercontainer is started by a oneshot unit with `docker run -d` (not oci-containers) so its watchtower can update it.
Docker-published ports bypass the NixOS firewall; `custom.services.lan.interfaces` drops LAN traffic to them in the
`nixos-docker-lan` chain (jumped to from DOCKER-USER), except `lan.allowed{TCP,UDP}Ports` (Pi-hole adds 53).
cloudflared runs a remotely managed tunnel: ingress rules are edited in the Cloudflare dashboard and target container
names on `cloudflare_network` (`http://n8n:5678`, `http://nextcloud-aio-apache:11000`, ...).

**Home Manager:**
```
flake.nix (homeConfigurations."astroreen@<host>")
  → home/${username}/${host}/home.nix              (e.g. home/astroreen/laptop/home.nix)
    → ../common/base.nix
        → ../profiles/terminal/{shell,devenv.nix,ranger.nix}, ../profiles/terminal/ai/{opencode,claude}
        → ../profiles/lang/{javascript,python}.nix
    → ../common/desktop.nix                        (laptop/pc only)
        → ../profiles/style/{cursor/breeze, theme/dark/adwaita}
        → ../profiles/apps/*  (apps, localsend, qview, postman, clipboard, emoji-picker, screenshot, vesktop, vscode, obs, lutris,
          nautilus, gnome-text-editor, kdeconnect, vnc, tailscale, browser, music, minecraft, hyprmod, t3code)
        → ../profiles/terminal/{shell/kitty,wine,htop}.nix, ../profiles/terminal/ai/fabric
        → ../../modules/terminal/dictation           (faster-whisper server + socket PTT daemon + Quickshell overlay)
        → ../profiles/lang/{java,csharp,flutter}.nix
        → ../profiles/wm/hyprland                     (Hyprland + compositor-dispatcher binds; portal.nix: portal service fix + GTK portal dialog rule)
        → ../profiles/wm/keybinds                     (plain-command binds: media, volume, suspend, dictation)
        → ../profiles/wm/shell                        (→ ../../modules/wm/shell + caelestia/ dux/, each with binds.nix)
        → ./hyprland/settings.nix                     (personal Hyprland input, generic window rules, layout binds)
    → ./hyprland/settings.nix                      (host-specific Hyprland binds/monitors)
```
In `home/astroreen/pc/home.nix` only, also imports `../profiles/apps/arduino.nix` and
`../../modules/terminal/ai/lmstudio.nix` (the pc-only LMStudio package).

Reusable HM modules (not profiles), under `home/modules/`:
- `home/modules/terminal/ai/` holds MCP servers, the Meridian proxy, and the `custom.ai.{agent,command,skill}` payload dirs + options — the single place that wires opencode and claude-code.
- `home/modules/terminal/dictation/` has push-to-talk dictation: `server.py` (faster-whisper HTTP, port 7777,
  CUDA, model `faster-whisper-large-v3`), `daemon.py` (unix-socket PTT controller; also its own client via
  `dictation-daemon start|stop|toggle|status`), `overlay/` (standalone Quickshell `qs -c dictation-overlay`).
  WM-agnostic; imported from `home/astroreen/common/desktop.nix`. The hold-to-talk bind is `custom.keybinds.binds.dictation`
  in `home/astroreen/profiles/wm/keybinds/default.nix` (`SUPER + F9` toggles: press to start, press again to stop/transcribe).
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
- Hyprland uses Lua config (`configType = "lua"`), not `hyprland.conf`. Settings are attrsets with `_args` + `lib.generators.mkLuaInline` dispatchers. Compositor-dispatcher binds live in `home/astroreen/profiles/wm/hyprland/binds.nix` (as `custom.keybinds` with `hyprland.dispatch`); host overrides in `home/astroreen/{laptop,pc}/hyprland/settings.nix`
- `nix-ld` is enabled on both hosts so prebuilt ELF binaries run without patching
- No automated test suite; validate with `dry-build` / `dry-activate`
- Desktop shell is per host: `custom.caelestia.enable` or `custom.dux.enable` (Dux Shell, ex-DankMaterialShell, `inputs.dux-shell` pinned to a release tag); enabling both fails an assertion. Generic modules in `home/modules/wm/shell/`, preconfigured profiles (packages, overrides, `binds.nix`) in `home/astroreen/profiles/wm/shell/`
- App-specific Hyprland window rules live with the app's profile (`profiles/apps/{qview,postman,localsend,clipboard}.nix`), not in `common/desktop/hyprland/settings.nix`, which keeps only generic rules (modal, classless, content, gcr-prompter)
- Keybinds: `custom.keybinds.binds.<name> = { key; exec | global | hyprland.dispatch; locked; repeating; description; }` (`description` defaults to the name in words; rendered as a one-line opts table because dux's keybind parser reads `hl.bind` line by line) (`home/modules/wm/keybinds`), translated per WM (Hyprland backend only so far). Profile values are `mkDefault`, so a host overrides a field or sets `.enable = false` directly. Both shells use the same names (`launcher`, `lock`, `screenshot`, ...), so an override follows the active shell. Plain commands go in `profiles/wm/keybinds`, shell actions in `profiles/wm/shell/<shell>/binds.nix`, Hyprland dispatchers in `profiles/wm/hyprland/binds.nix`, app launchers next to their app (`terminal` in kitty.nix, `fileManager` in nautilus, `emoji`, `clipboard`, `vncCycleOutput`), layout switching in `common/desktop/default.nix`. Never add raw `wayland.windowManager.hyprland.settings.bind` entries
- The `caelestia-shell` config (`~/.config/caelestia/shell.json`) and dux's (`~/.config/dms/settings.json`) are real files merged via `home.activation` (`home/modules/wm/shell/lib.nix`, jq), never symlinked: `settings` only fills keys the file lacks (what the shell's settings UI saved wins; `overrideSettings = true` makes `settings` win instead), `settingsOverrides` always wins. Per-host defaults: `home/astroreen/<host>/assets/{caelestia-shell-config,dux-settings}.json`; refresh the dux one from the live host with `sync-dux-config`
- Dux on Hyprland: `custom.dux.hyprlandIncludes` appends `require("dms.<name>")` for the fragments dux writes under `~/.config/hypr/dms/` (outputs, binds-user, layout, ...) so its Displays/Keybinds pages work despite the read-only `hyprland.lua`; activation `touch`es missing fragments. The dms package carries `home/modules/wm/shell/dux/mpris-display-name.patch` (QML: player names from desktop entries; Pear is renamed in `profiles/apps/music.nix`) and `screencopy-transform.patch` (Go: Hyprland 0.57 hands out already-rotated screencopy frames, so `dms screenshot` must not rotate 90/270 degree outputs again). Under dux, Print opens the QuickCapture plugin, SUPER+Print is grim + slurp into satty. Under dux, SUPER+V is dux's clipboard and copyq is off (`profiles/apps/clipboard.nix`), SUPER+Period the emojiPicker plugin instead of the rofi picker
- Dux plugins: `custom.dux.plugins.<plugin id>.src` (+ default `settings`) links the plugin into `~/.config/dms/plugins/` and enables it in the writable `plugin_settings.json`. The preconfigured set lives in `home/astroreen/profiles/wm/shell/dux/plugins/`: every source pinned by rev + hash after a security review, with `*.patch` fixes for injections found; runtime tools they call are in its `home.packages`. Never bump a plugin rev or add one without reviewing its code (plugins run with full user privileges)
- HyprMod reads `hyprland.lua` with hyprland-config's Lua reader, which runs every `hl.on` callback; `profiles/apps/hyprmod.nix` loads `hyprmod-guard.lua` first to disable `os.execute` there, otherwise HM's shutdown hook stops `hyprland-session.target` (and the shell) on every HyprMod launch
- Opencode alias: `oc = "opencode"`
- Opencode theme: `gruvbox`; plugins: md-table-formatter, notifier, dcp (context compression), vibeguard, anthropic-auth, claude-auth
- `inputs.caveman` (flake=false) is a plain source tree for the caveman opencode skill
- `nixpkgs-stable` (`nixos-25.11`) is available as `pkgs-stable` in all module specialArgs
