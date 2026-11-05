"""Nautilus extension: copy the absolute or relative path of selected files.

Adds "Copy Absolute Path" and "Copy Relative Path" entries to the file context
menu. They only appear when every selected item is a regular file (not a
folder). Several selected files are copied one path per line.

The relative path is taken from the root of the git repository holding the
file; outside a repository it falls back to the home directory (~/...).

Installed to ~/.local/share/nautilus-python/extensions/ by nautilus.nix.
"""

from gi import require_version

try:
    require_version("Gtk", "4.0")
    require_version("Gdk", "4.0")
except ValueError:
    require_version("Gtk", "3.0")
    require_version("Gdk", "3.0")

import os

from gi.repository import Gdk, Gio, GObject, Nautilus


def _git_root(path):
    directory = os.path.dirname(path)
    while True:
        if os.path.exists(os.path.join(directory, ".git")):
            return directory
        parent = os.path.dirname(directory)
        if parent == directory:
            return None
        directory = parent


def _relative(path):
    root = _git_root(path)
    if root is not None:
        return os.path.relpath(path, root)
    home = os.path.expanduser("~")
    if path.startswith(home + os.sep):
        return "~/" + os.path.relpath(path, home)
    return path


class CopyPathExtension(GObject.GObject, Nautilus.MenuProvider):
    """Adds "Copy Absolute Path" / "Copy Relative Path" to the file menu."""

    def _copy(self, _menu, paths):
        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.set_content(Gdk.ContentProvider.new_for_value("\n".join(paths)))

    def get_file_items(self, *args):
        files = args[-1]
        if not files or any(file.is_directory() for file in files):
            return []

        # Virtual views (Recent, Starred) list recent:// etc. locations; the
        # activation URI points at the real file.
        paths = [
            Gio.File.new_for_uri(file.get_activation_uri()).get_path()
            for file in files
        ]
        # Remote locations (sftp://, ...) have no local path.
        if None in paths:
            return []

        absolute = Nautilus.MenuItem(
            name="CopyPathExtension::absolute",
            label="Copy Absolute Path",
            tip="Copy the full path of the selected file",
        )
        absolute.connect("activate", self._copy, paths)

        relative = Nautilus.MenuItem(
            name="CopyPathExtension::relative",
            label="Copy Relative Path",
            tip="Copy the path relative to the git repository (or home)",
        )
        relative.connect("activate", self._copy, [_relative(p) for p in paths])

        return [absolute, relative]
