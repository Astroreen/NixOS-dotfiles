let
  createMcpServer =
    {
      enable ? false,
      name ? "",
      type ? "local",
      command ? "",
      args ? [ ],
      env ? { },
      ...
    }:
    {
      inherit
        enable
        name
        type
        command
        args
        env
        ;
    };
in
{
  obsidian = createMcpServer {
    enable = true;
    name = "obsidian";
    type = "local";
    command = "docker";
    args = [
      "run"
      "-i"
      "--rm"
      "-e"
      "OBSIDIAN_HOST"
      "-e"
      "OBSIDIAN_API_KEY"
      "mcp/obsidian"
    ];
    env = {
      OBSIDIAN_HOST = "host.docker.internal"; 
      OBSIDIAN_API_KEY = "{env:OBSIDIAN_API_KEY}";
    };
  };
}
