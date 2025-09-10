{pkgs, ...}:
{
    programs.openvpn3 = {
        enable = true;
        package = pkgs.openvpn3;
    };

    environment.systemPackages = with pkgs; [
        openvpn
    ];
}
