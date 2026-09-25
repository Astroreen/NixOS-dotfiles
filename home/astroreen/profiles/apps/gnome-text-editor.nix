{ pkgs, ... }:
{
  home.packages = [
    pkgs.gnome-text-editor
  ];

  # The package's desktop entry sets DBusActivatable=true. When the session
  # D-Bus bus (dbus-broker) was started before this package was installed, the
  # org.gnome.TextEditor service is not registered, so launching via GIO /
  # double click fails with "The name is not activatable". Overriding with
  # DBusActivatable=false makes GIO exec the binary directly instead.
  xdg.desktopEntries."org.gnome.TextEditor" = {
    name = "Text Editor";
    genericName = "Text Editor";
    comment = "View and edit text files";
    exec = "gnome-text-editor %U";
    icon = "org.gnome.TextEditor";
    terminal = false;
    categories = [
      "GNOME"
      "GTK"
      "Utility"
      "TextEditor"
    ];
    mimeType = [
      "text/plain"
      "application/x-zerosize"
    ];
    settings = {
      DBusActivatable = "false";
      StartupNotify = "true";
    };
  };

  # Default handler for text-based files on double click.
  # Project files are still opened in VSCode explicitly.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/*" = "org.gnome.TextEditor.desktop";
      "application/json" = "org.gnome.TextEditor.desktop";
      "application/xml" = "org.gnome.TextEditor.desktop";
      "application/x-yaml" = "org.gnome.TextEditor.desktop";
      "application/toml" = "org.gnome.TextEditor.desktop";
      "application/x-shellscript" = "org.gnome.TextEditor.desktop";
      "application/x-desktop" = "org.gnome.TextEditor.desktop";
      "application/x-zerosize" = "org.gnome.TextEditor.desktop";
    };
  };
}
