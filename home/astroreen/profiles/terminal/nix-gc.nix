# The system nix.gc runs as root and never expires generations in
# ~/.local/state/nix/profiles (home-manager, nix profile), so they pile up
# and keep old store paths alive. This user timer expires them.
_: {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
