_: {
  # Quickshell desktop shells. Both are imported; the host picks one with
  # custom.caelestia.enable or custom.dux.enable.
  imports = [
    ../../../../modules/wm/shell # custom.caelestia / custom.dux options
    ./caelestia # Caelestia shell
    ./dux # Dux shell
  ];
}
