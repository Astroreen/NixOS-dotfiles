"""Nautilus extension: create a new empty file in the current folder.

Adds a "New File…" entry to the folder background context menu, mirroring the
built-in "New Folder…" entry. The user types a name (with extension) and an
empty file is created in the current directory.

Installed to ~/.local/share/nautilus-python/extensions/ by nautilus.nix.
"""

from gi import require_version

try:
    require_version("Gtk", "4.0")
except ValueError:
    require_version("Gtk", "3.0")

import os

from gi.repository import GObject, Gtk, Nautilus


class NewFileExtension(GObject.GObject, Nautilus.MenuProvider):
    """Adds a "New File…" entry to the folder background context menu."""

    def _show_error(self, message):
        dialog = Gtk.AlertDialog(message=message, modal=True)
        dialog.show(Gtk.Application.get_default().get_active_window())

    def _create(self, dialog, folder, entry):
        name = entry.get_text().strip()
        dialog.destroy()

        if not name:
            return

        directory = folder.get_location().get_path()
        if directory is None:
            return

        target = os.path.join(directory, name)
        try:
            # "x" fails if the file already exists, avoiding silent overwrite.
            with open(target, "x"):
                pass
        except FileExistsError:
            self._show_error(f'"{name}" already exists.')
        except OSError as error:
            self._show_error(f"Could not create file: {error.strerror}")

    def _new_file(self, _menu, folder):
        dialog = Gtk.Window(
            title="New File",
            transient_for=Gtk.Application.get_default().get_active_window(),
            modal=True,
        )
        # Size to the content (198x104) and keep it fixed; the matching
        # Hyprland window rule pins the same size so the main Nautilus rule
        # (1400x800) does not stretch this dialog.
        dialog.set_resizable(False)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(12)
        box.set_margin_bottom(12)
        box.set_margin_start(12)
        box.set_margin_end(12)

        entry = Gtk.Entry()
        entry.set_placeholder_text("name.ext")
        entry.set_activates_default(True)
        box.append(entry)

        buttons = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        buttons.set_halign(Gtk.Align.END)

        cancel = Gtk.Button(label="Cancel")
        create = Gtk.Button(label="Create")
        create.add_css_class("suggested-action")
        buttons.append(cancel)
        buttons.append(create)
        box.append(buttons)

        dialog.set_child(box)
        dialog.set_focus(entry)

        cancel.connect("clicked", lambda _widget: dialog.destroy())
        create.connect("clicked", lambda _widget: self._create(dialog, folder, entry))
        entry.connect("activate", lambda _widget: self._create(dialog, folder, entry))

        dialog.present()

    def get_background_items(self, *args):
        folder = args[-1]
        item = Nautilus.MenuItem(
            name="NewFileExtension::new_file",
            label="New File…",
            tip="Create a new empty file in this folder",
        )
        item.connect("activate", self._new_file, folder)
        return [item]
