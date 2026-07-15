{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    kitty # Kitty terminal emulator
  ];
}
