{
  pkgs,
  inputs,
  host,
  pkgs-stable,
  ...
}:
{
  # Unprivileged account for autonomous agents. Not in wheel or docker:
  # either one would effectively give an agent root.
  users.users.agent = {
    isNormalUser = true;
    description = "AI agents";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    linger = true; # User services and tmux sessions keep running without a login
  };

  # The agent's own Home Manager config is set by the host
  # (home-manager.users.agent).
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs host pkgs-stable; };
  };
}
