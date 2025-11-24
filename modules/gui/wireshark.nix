{ pkgs, ... }:
{
  programs.wireshark = {
    enable = true;
    dumpcap.enable = true; # Allow use for users with group "wireshark"
    package = pkgs.wireshark;
  };
}
