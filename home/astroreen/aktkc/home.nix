{ pkgs, lib, ... }:
{
  imports = [
    ../common/server # Headless server home shared by all server hosts

    ./astro-dashboard.nix
  ];
}
