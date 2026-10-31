_: {
  imports = [
    ./hybrid-gpu.nix # custom.power.hybridGpu
    ./charge-limit.nix # custom.power.chargeLimit
    ./tunables.nix # custom.power.tunables
  ];
}
