{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Every plugin is pinned to the commit that was reviewed (2026-10-29): no
  # network access beyond what is listed, no eval/obfuscation/self-update.
  # Bumping a rev means reviewing the new code first; plugins run with full
  # user privileges. The *.patch files fix shell/QML injections found then.
  hthienloc = pkgs.fetchFromGitHub {
    owner = "hthienloc";
    repo = "dms-plugins";
    rev = "ccb969fe96e36e3c61ca6b0814fbc1573b0e4de0";
    hash = "sha256-nTUS8r+0LGgxYzJzSuCQ69dkL3Oi+nPT0yL465rKDOk=";
  };
  duxPlugins = pkgs.fetchFromGitHub {
    owner = "duxlabs-dev";
    repo = "dux-plugins";
    rev = "96201bd52b148b311c74eafca3988cc4d0cd0d8f";
    hash = "sha256-zrbWy8IkiCrWv9EjIipnolbiF4SmikATSFRGc/Yi/Z4=";
  };

  # A plugin directory of a monorepo, with optional patches
  plugin =
    src: dir: patches:
    if patches == [ ] then
      "${src}/${dir}"
    else
      pkgs.applyPatches {
        name = "dux-plugin-${dir}";
        src = "${src}/${dir}";
        inherit patches;
      };
in
{
  config = lib.mkIf config.custom.dux.enable {
    custom.dux.plugins = {
      # Screenshot/recording editor (annotate, OCR, QR, PDF export).
      # Patch: picked image paths were spliced into Qt.createQmlObject code.
      quickCapture.src = plugin hthienloc "quickCapture" [ ./quickcapture-qml-escape.patch ];
      # Emoji picker (SUPER + Period under dux, see ../binds.nix)
      emojiPicker = {
        src = plugin hthienloc "emojiPicker" [ ];
        # Paste the picked emoji instead of only copying it (plugin default: "copy")
        settings.defaultAction = "paste";
      };

      # Phone integration over KDE Connect ("PhoneConnect").
      # Patch: a phone filename with $(...) ran as a command on drag.
      dankKDEConnect.src = plugin duxPlugins "DankKDEConnect" [ ./kdeconnect-drag-argv.patch ];
      dankPomodoroTimer.src = plugin duxPlugins "DankPomodoroTimer" [ ];
      # Launcher "!" : switch to/close Hyprland windows (uses the Lua dispatchers)
      dankHyprlandWindows.src = plugin duxPlugins "DankHyprlandWindows" [ ];
      # Launcher "\" : search keybinds. Patch: copied key text went through sh -c.
      dankLauncherKeys.src = plugin duxPlugins "DankLauncherKeys" [ ./launcherkeys-copy-argv.patch ];
      # Bar widgets running your own shell commands. Its settings are code:
      # never paste someone else's plugin_settings.json entries for it.
      dankActions.src = plugin duxPlugins "DankActions" [ ];

      # Live Wallpaper Engine scenes via linux-wallpaperengine. Needs Wallpaper
      # Engine (Steam app 431960) installed for its assets + workshop items.
      # Patch: linux-wallpaperengine's own fullscreen pause counts fullscreen
      # windows on every monitor and workspace (hidden ones too) and stops all
      # wallpapers. `pauseOnFullscreen` freezes only the monitor whose visible
      # workspace has a fullscreen or maximized window, so keep the per-output
      # `noFullscreenPause = true` (the engine's own check) alongside it.
      linuxWallpaperEngine = {
        src = pkgs.applyPatches {
          name = "dux-plugin-linuxWallpaperEngine";
          src = pkgs.fetchFromGitHub {
            owner = "sgtaziz";
            repo = "dms-wallpaperengine";
            rev = "e96718f5038f54546311a239ef0f6622f15c515a";
            hash = "sha256-SSNXZl7DFA7cKaSt4FaXcQ58IjcHxvyi/zVKMwvHXdQ=";
          };
          patches = [ ./wallpaperengine-fullscreen-per-output.patch ];
        };
        settings = {
          pauseOnFullscreen = true;
          pauseOnBattery = true; # only does something on the laptop

        };
      };

      # Launcher "=": calculator. Keep the default JavaScript engine: the qalc
      # engine evaluates every keystroke and qalc's command() runs programs.
      calculator.src = pkgs.fetchFromGitHub {
        owner = "rochacbruno";
        repo = "DankCalculator";
        rev = "a27b80ad8c3dd42da11af83461674fb362817515";
        hash = "sha256-fw5ySERKzK4iSzZhneIp06zFCP1FnxscbI/COzmPAGQ=";
      };

      # Full Tailscale manager (accounts, routes, DNS, Taildrop) on top of the
      # built-in widget. Its pkexec login/operator buttons can't work on NixOS
      # (no setuid wrapper); the operator is already set, use
      # `sudo tailscale login --operator=$USER` to log in.
      dankscale.src = pkgs.fetchFromGitHub {
        owner = "dwright134";
        repo = "dms-dankscale";
        rev = "27d12a9a348fe9fa94d8695e399fb6fc4cb5e6d0";
        hash = "sha256-orx20A7ZX9Hp3WxMEZhFSvLWFQ53/PWmRJrGqZGARrc=";
      };

      # Full-screen power menu (`dms ipc call fullscreenPowerMenu toggle`).
      # Single keys act immediately (P = power off, R = reboot). Leave its
      # Logout command field empty: once touched it saves
      # `loginctl terminate-session`, which fails without a session id.
      fullscreenPowerMenu.src = pkgs.fetchFromGitHub {
        owner = "JDKamalakar";
        repo = "DMS-Fullscreen_Power_Menu";
        rev = "3ec625d2e0105a063492249ef732a0ca91cf91b8";
        hash = "sha256-aKV0zwLCvRZdZdRfrbD6vjyFS6E7ckqmzOUy15oEwJ4=";
      };

      # Launcher "nix": search nixpkgs and `nix run` a package
      nixPackageRunner.src = pkgs.fetchFromGitHub {
        owner = "iahccc";
        repo = "NixPackageRunner";
        rev = "829ad93c15b7c0ec82a6d7483728029037442601";
        hash = "sha256-ur+1oN+QmTu7p5ZMpL3rCd4JGYbkerko4twa+tH6uvg=";
      };
    };

    # Runtime tools the plugins call by name
    home.packages = with pkgs; [
      # quickCapture
      imagemagick
      tesseract # OCR
      zbar # QR codes
      wf-recorder
      python3Packages.img2pdf
      pulseaudio # pactl (recording audio source)
      # emojiPicker
      noto-fonts-color-emoji
      # dankKDEConnect: drag phone files out of the panel
      ripdrag
      # linuxWallpaperEngine. nixpkgs build: "ropetrail" particles (shooting
      # stars) freeze into lines (Almamu/linux-wallpaperengine#682). sgtaziz's
      # fork @ 88060427 fixes that but renders scenes far too dark (lost the
      # scheme/clear colour), so it is not used.
      linux-wallpaperengine
      # dankscale: default Taildrop download folder lookup
      xdg-user-dirs
    ];
  };
}
