# Helpers shared by the service modules in this directory.
{ lib }:
{
  # Common options of a single-container service.
  containerOptions =
    {
      name,
      image,
      port,
      dataDir,
    }:
    {
      image = lib.mkOption {
        type = lib.types.str;
        default = image;
        description = "Container image of ${name}.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = port;
        description = "Port ${name} listens on, inside the container and on the host.";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = dataDir;
        description = ''
          Host directory with the state of ${name}. Kept root-only (0700), so
          other host accounts cannot read it whatever uid the container uses.
        '';
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Extra environment variables for ${name}.";
      };
      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/var/lib/secrets/${name}.env";
        description = "File with secret environment variables, created by hand on the host.";
      };
    };

  # Orders a container after the shared network it joins.
  afterNetwork = name: {
    ${name} = {
      after = [ "docker-network-services.service" ];
      requires = [ "docker-network-services.service" ];
    };
  };
}
