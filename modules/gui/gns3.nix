{ pkgs, ... }:
{

  services.gns3-server = {
    enable = true;
    auth.user = "astroreen";
    ubridge.enable = true;
    dynamips.enable = true;
    vpcs.enable = true;
    log.debug = true;
  };

  environment.systemPackages = with pkgs; [
    qemu
    gns3-gui
    gns3-server
    ubridge
    dynamips # Cisco router emulator
    vpcs    # Virtual PC Simulator
    inetutils # telnet
  ];

  systemd.services.gns3-server.serviceConfig = {
    DeviceAllow = [ "/dev/kvm" ];
    SupplementaryGroups = [ "kvm" ];
    PrivateDevices = false;
    Environment = [ "PATH=/run/current-system/sw/bin:/usr/bin:/bin" ];
  };

  networking.firewall = {
    allowedTCPPorts = [ 3080 ];
    allowedUDPPorts = [ 3080 ];
  };
}
