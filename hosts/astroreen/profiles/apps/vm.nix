{ pkgs, lib, ... }:
{
  # Virtualization stack for running Windows 11 guests (QEMU/KVM + libvirt).
  # GUI: virt-manager. Windows 11 requires UEFI (OVMF, shipped with QEMU by
  # default) and a TPM 2.0 (swtpm).

  # libvirt daemon. Also enabled by profiles/lang/flutter.nix for the Android
  # emulator; kept here so this module is self-contained.
  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      # Software TPM 2.0 — required by Windows 11.
      swtpm.enable = true;
    };
  };

  # USB redirection into the guest (USB dongles, license keys, etc.).
  virtualisation.spiceUSBRedirection.enable = true;

  # virt-manager GUI + standalone SPICE/VNC viewer.
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
  ];

  # virt-manager's first-run hypervisor auto-detection only probes FHS paths
  # (/usr/bin/qemu*, /usr/libexec/qemu-kvm), which don't exist on NixOS, so it
  # reports "Could not detect a default hypervisor". Pre-seed the QEMU/KVM
  # system connection so virt-manager skips detection and connects directly.
  programs.dconf.profiles.user.databases = [
    {
      settings = with lib.gvariant; {
        "org/virt-manager/virt-manager/connections" = {
          uris = [ "qemu:///system" ];
          autoconnect = [ "qemu:///system" ];
        };
      };
    }
  ];
}
