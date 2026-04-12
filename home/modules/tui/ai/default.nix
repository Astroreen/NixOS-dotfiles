{ config, lib, ... }: 
let 
  cfg = config.custom.ai;
in 
{
  imports = [
    ./skills
    ./meridian.nix
  ];

  options = with lib; {
    custom.ai = {
      settings = mkOption {
        description = "AI settings";
        default = { };
        type = types.submodule {
          options = {
            configDir = mkOption {
              type = types.either types.str types.path;
              default = ".config/opencode";
              description = "Directory for AI skill config files in HOME directory (e.g. learn skill's feedback and learning data)";
            };
          };
        };
      };
    };
  };
}
