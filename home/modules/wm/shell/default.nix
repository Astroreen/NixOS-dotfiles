{ config, ... }:
{
  # Quickshell desktop shells. At most one may be enabled per host.
  imports = [
    ./caelestia
    ./dux
  ];

  # Both shells own org.freedesktop.Notifications and the same keybinds.
  assertions = [
    {
      assertion = !(config.custom.caelestia.enable && config.custom.dux.enable);
      message = "custom.caelestia and custom.dux cannot be enabled at the same time";
    }
  ];
}
