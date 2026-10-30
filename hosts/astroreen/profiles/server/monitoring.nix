{ pkgs, ... }:
{
  # Uptime checks and status page, web UI on :3001 (tailnet only).
  services.uptime-kuma = {
    enable = true;
    settings.HOST = "0.0.0.0";
  };

  # Minute-level sar history (CPU, memory, swap, load, network, PSI, plus
  # disks) in /var/log/sa, kept 7 days. Times in the host's zone (EET):
  #   sar -r -f /var/log/sa/saDD -s 00:30:00 -e 00:36:00; sar -q PSI ...
  services.sysstat = {
    enable = true;
    collect-frequency = "*:*:00";
  };
  environment.etc."sysconfig/sysstat".text = ''
    HISTORY=7
    SADC_OPTIONS="-S DISK"
  '';
  environment.systemPackages = [ pkgs.sysstat ]; # sar, iostat, pidstat
}
