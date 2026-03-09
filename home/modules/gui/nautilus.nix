{ ... }:
{
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
    };
  };
}
