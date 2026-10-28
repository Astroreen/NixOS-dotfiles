{ config, lib, ... }:
{
  # Workstation layer on top of ./base.nix: Hyprland, desktop shell, GUI apps.
  imports = [
    ../base # Headless base shared by every host (desktop and server)

    # Style
    ../../profiles/style/cursor/breeze # Breeze cursor style
    ../../profiles/style/theme/dark/adwaita # Adwaita dark theme

    # Apps (gui)
    ../../profiles/apps/apps.nix # Standard apps to install
    ../../profiles/apps/localsend.nix # LocalSend always-on file transfer server
    ../../profiles/apps/qview.nix # qView image viewer
    ../../profiles/apps/postman.nix # Postman API client
    ../../profiles/apps/clipboard.nix # Clipboard ui
    ../../profiles/apps/emoji-picker # Emoji picker (SUPER + Period)
    ../../profiles/apps/screenshot.nix # Screenshot tooling (satty + swappy shim)
    ../../profiles/apps/vesktop.nix # VDesktop configuration
    ../../profiles/apps/vscode # VSCode
    ../../profiles/apps/obs.nix # OBS Studio
    ../../profiles/apps/lutris.nix # Lutris game manager
    ../../profiles/apps/nautilus # Nautilus file manager configuration
    ../../profiles/apps/gnome-text-editor.nix # Default text editor for text-based files
    ../../profiles/apps/kdeconnect.nix # KDE Connect configuration
    ../../profiles/apps/vnc.nix # VNC server and client configuration
    ../../profiles/apps/tailscale.nix # Tailscale tray and client configuration
    ../../profiles/apps/browser.nix # Browser configuration
    ../../profiles/apps/music.nix # Music apps configuration
    ../../profiles/apps/minecraft.nix # Minecraft configuration
    ../../profiles/apps/hyprmod.nix # HyprMod settings app for Hyprland (mutable hyprland-gui.lua)
    ../../profiles/apps/t3code # T3 Code theme + settings + keybindings sync

    # Terminal apps (tui)
    ../../profiles/terminal/shell # Shell settings
    ../../profiles/terminal/shell/kitty.nix # Kitty terminal emulator
    ../../profiles/terminal/shell/zsh.nix # Zsh shell
    ../../profiles/terminal/shell/fastfetch.nix # Fastfetch system information tool
    ../../profiles/terminal/wine.nix # Wine configuration
    ../../profiles/terminal/htop.nix # Htop on steroids (NeoHtop GUI)
    ../../../modules/terminal/dictation # Push-to-talk voice dictation (faster-whisper)
    ../../profiles/terminal/ai/fabric # Fabric AI CLI tool

    # Languages
    ../../profiles/lang/java.nix
    ../../profiles/lang/csharp.nix
    ../../profiles/lang/flutter.nix

    # Windows manager (wm)
    ../../profiles/wm/hyprland # Hyprland window manager
    ../../profiles/wm/keybinds # WM-agnostic keybinds (custom.keybinds)
    ../../profiles/wm/shell # Desktop shell: host enables custom.caelestia or custom.dux
  ];

  # Wayland, X, etc. support for session vars
  systemd.user.sessionVariables = config.home.sessionVariables;

  # Push-to-talk voice dictation (local faster-whisper server + socket daemon + overlay)
  custom.dictation = {
    enable = lib.mkDefault true;
    host = lib.mkDefault "127.0.0.1";
  };

  wayland.windowManager.hyprland = {
    # Hyprland settings
    settings = lib.mkMerge [
      (import ./hyprland/settings.nix { inherit lib; })
      {
        # Why is it not in binds.nix? Because these are my personal keybinds, and not general Hyprland ones
        bind =
          let
            dsp = lua: lib.generators.mkLuaInline lua;
          in
          [
            # Switch keyboard layout directly via hyprctl IPC
            { _args = [ "SHIFT + ALT + E" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 0\")") ]; } # English (us)
            { _args = [ "SHIFT + ALT + R" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 1\")") ]; } # Russian (ru)
            { _args = [ "SHIFT + ALT + L" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 2\")") ]; } # Lithuanian (lt)
          ];
      }
    ];
  };
}
