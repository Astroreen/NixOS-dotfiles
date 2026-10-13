{
  libnotify,
  writeShellApplication,
  satty,
  wl-clipboard,
}:

# swappy -> satty shim: the caelestia screenshot pipeline (cli
# screenshot.py + shell AreaPicker.qml) hardcodes `swappy -f <file>`.
# Translate that call to satty: Enter copies to clipboard (+ saves a
# file copy, --save-after-copy) and exits early; the output file goes
# to $CAELESTIA_SCREENSHOTS_DIR (default ~/Pictures/Screenshots).
# satty does not create parent dirs -> mkdir -p first.
# satty's own notifications go through GIO GNotification; its fdo
# backend drops FileIcon images (glib work item 1457) and caelestia
# falls back to a glyph icon -> run satty with --disable-notifications
# and send a raw fdo notification with an image-path thumbnail after
# the save instead.
writeShellApplication {
  name = "swappy";
  runtimeInputs = [
    libnotify
    satty
    wl-clipboard
  ];
  text = ''
    file=""
    out_dir="''${CAELESTIA_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -f|--file)
          file="''${2:?swappy-shim: -f requires a file argument}"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [ -z "$file" ]; then
      echo "swappy-shim: missing -f <file>" >&2
      exit 1
    fi
    mkdir -p "$out_dir"
    satty -f "$file" \
      --copy-command wl-copy \
      --disable-notifications \
      --early-exit all \
      --actions-on-enter save-to-clipboard \
      --save-after-copy \
      --output-filename "$out_dir/satty-%Y-%m-%d_%H:%M:%S.png"
    new_file=""
    for f in "$out_dir"/satty-*.png; do
      [ -e "$f" ] || continue
      if [ "$f" -nt "$file" ]; then
        new_file="$f"
        break
      fi
    done
    if [ -n "$new_file" ]; then
      notify-send -a Satty -i satty \
        -h string:image-path:"$new_file" \
        "Satty" "File saved to '$new_file'"
    fi
  '';
}
