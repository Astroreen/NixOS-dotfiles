{ config, ... }:
{
  custom.ai.deepseekHarness = {
    enable = true;
    settings = {
      host = "127.0.0.1";
      port = 3080;
      dshHome = "${config.home.homeDirectory}/.dsh";
    };
    plugins = {
      # Exmaple: "@deepseek-ai/dsh-plan-mode" = { profile = "default"; };
    };
  };
}
