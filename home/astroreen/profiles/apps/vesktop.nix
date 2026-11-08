{ pkgs, lib, ... }:
let
  # Chromium/Electron flags to enable NVIDIA hardware video acceleration
  nvidia-vaapi-flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
  ];

  # Discord moved to rspack (2026-11); older Vencord breaks the client into a
  # blank window, and Vesktop's own Vencord updater needs GitHub. Pinned here
  # until nixpkgs ships >= 1.15.16. The source is the official Codeberg mirror.
  vencord = pkgs.vencord.overrideAttrs (
    finalAttrs: old: {
      version = "1.15.16";
      src = pkgs.fetchFromGitea {
        domain = "codeberg.org";
        owner = "vee";
        repo = "cord";
        tag = "v${finalAttrs.version}";
        hash = "sha256-aUJubLJpyLAZWiOezqFxPY6oVPgWVPQpajFqrJvrO9U=";
      };
      # nixpkgs' @types/react lockfile fix is upstream by now
      patches = [ ];
      postPatch = "";
      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs) pname src;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-HS8uZNepvDefjrsG3buVLFCVv7sHvazcwdpcT3EQ/78=";
      };
      env = old.env // {
        VENCORD_REMOTE = "Vendicated/Vencord";
      };
    }
  );

  vesktop-gpu = (pkgs.vesktop.override { inherit vencord; }).overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/vesktop \
        ${lib.concatStringsSep " \\\n      " (
          map (f: "--add-flags ${lib.escapeShellArg f}") nvidia-vaapi-flags
        )}
    '';
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  });
in
{
  programs.vesktop = {
    enable = true;
    package = vesktop-gpu;
    # The module sets withSystemVencord from this, overriding the package's own
    vencord.useSystem = true;
  };

  # Vesktop registers itself for discord:// links on every start (xdg-mime),
  # which replaced the home-manager mimeapps.list symlink with a regular file
  # and broke the next `home switch`. Declared here, it is already the default.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."x-scheme-handler/discord" = "vesktop.desktop";
  };

  wayland.windowManager.hyprland.settings = {
    on = [
      {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"[workspace 3 silent] vesktop\")\nend")
        ];
      }
    ];

    window_rule = [
      {
        match.class = "discord|vesktop";
        fullscreen = true;
        workspace = "3 silent";
      }
    ];
  };
}
