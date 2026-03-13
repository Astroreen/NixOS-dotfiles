{ ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        enabled = false;
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        headers = { };
      };

      playwright = {
        enabled = false;
        type = "local";
        command = "docker";
        args = [
          "run"
          "-i"
          "--rm"
          "mcp/playwright"
        ];
      };

      youtube-transcript = {
        enabled = false;
        type = "local";
        command = "docker";
        args = [
          "run"
          "-i"
          "--rm"
          "mcp/youtube-transcript"
        ];
      };
    };
  };
}
