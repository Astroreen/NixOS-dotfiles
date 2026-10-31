{ config, lib, ... }:
let
  cfg = config.custom.power.tunables;
in
{
  # The safe subset of `powertop --auto-tune`: it would also autosuspend every
  # USB device, which drops the first key press or mouse move of some devices.
  options.custom.power.tunables = {
    enable = lib.mkEnableOption "powertop's safe laptop power tunables (PCI runtime PM, no NMI watchdog, lazier writeback)";

    pciRuntimePm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Let every PCI device runtime-suspend when idle (`power/control = auto`).";
    };

    dirtyWritebackSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 15;
      description = "Interval of the kernel's dirty page writeback (kernel default: 5 s).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = lib.mkIf cfg.pciRuntimePm ''
      ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"
    '';

    boot.kernel.sysctl = {
      # A periodic hardware interrupt per CPU, only useful for kernel debugging
      "kernel.nmi_watchdog" = 0;
      "vm.dirty_writeback_centisecs" = cfg.dirtyWritebackSeconds * 100;
    };
  };
}
