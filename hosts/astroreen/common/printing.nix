{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      foo2zjs
    ];
  };

  environment.systemPackages = with pkgs; [
    foo2zjs # Printer drivers
  ];
}
