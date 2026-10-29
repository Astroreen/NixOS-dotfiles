{ lib, ... }:
{
  imports = [
    ../../../../modules/wm/keybinds # custom.keybinds
  ];

  xdg = {
    desktopEntries."org.gnome.Nautilus" = {
      name = "Files";
      genericName = "File Manager";
      comment = "Access and organize files";
      icon = "org.gnome.Nautilus";
      exec = "nautilus --new-window %U";
      terminal = false;
      categories = [
        "GNOME"
        "GTK"
        "Utility"
        "FileManager"
      ];
      mimeType = [
        "inode/directory"
        "application/x-gnome-saved-search"
      ];
      settings = {
        Keywords = "Files;File Manager;Explorer;Browser;";
        StartupNotify = "true";
        X-GNOME-UsesNotifications = "true";
      };
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
      };
      # "Open With" Files on archives extracts them in place
      associations.added = lib.genAttrs [
        "application/gzip"
        "application/x-7z-compressed"
        "application/x-bzip2"
        "application/x-rar"
        "application/x-tar"
        "application/x-xz"
        "application/zip"
      ] (_: "org.gnome.Nautilus.desktop");
    };
  };

  wayland.windowManager.hyprland = {
    settings.window_rule = [
      # The "New File…" dialog is a separate toplevel that shares the main
      # window's app class, so the rule below would otherwise force it to
      # 1400x800. This more specific rule must come first: Hyprland applies the
      # first matching rule per property. 198x104 is the dialog's natural size.
      {
        match = {
          class = "^org.gnome.Nautilus";
          title = "New File";
        };
        size = "198 104";
        center = false;
        float = true;
      }
      {
        match.class = "^org.gnome.Nautilus";
        size = "1400 800";
        center = true;
        float = true;
      }
    ];
  };

  # File manager; floats centered at 1400x800 through the window rule above
  custom.keybinds.binds.fileManager = {
    description = lib.mkDefault "File manager";
    key = lib.mkDefault "SUPER + E";
    exec = lib.mkDefault "nautilus";
  };

  # "New File…" background context-menu entry (nautilus-python extension).
  home.file.".local/share/nautilus-python/extensions/nautilus-new-file.py".source =
    ./nautilus-new-file.py;
}
