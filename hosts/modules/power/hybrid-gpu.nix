{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.power.hybridGpu;

  # glvnd tries EGL vendors in file-name order and NVIDIA ships 10_nvidia.json,
  # so every Chromium/Electron app opened /dev/nvidia0 while probing it and the
  # dGPU never reached D3cold. Mesa first keeps apps on the iGPU; NVIDIA stays
  # as the fallback for what only it can drive (the compositor on outputs wired
  # to the dGPU), so it must not be dropped from the list.
  eglVendors = pkgs.runCommand "egl-vendors-igpu-first" { } ''
    mkdir -p $out
    ln -s /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json $out/10_mesa.json
    ln -s /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json $out/90_nvidia.json
  '';

  # Variables that hide the dGPU from an app, undone by nvidia-offload
  hidingVariables = {
    __EGL_VENDOR_LIBRARY_DIRS = "${eglVendors}";
    # The Vulkan loader initialises every ICD it finds (and the NVIDIA one
    # wakes the GPU), so here only a whitelist works.
    VK_DRIVER_FILES = lib.concatStringsSep ":" cfg.vulkanDrivers;
  }
  // lib.optionalAttrs cfg.hideCuda {
    # mpv/ffmpeg `hwdec=auto` tries NVDEC first and keeps a CUDA context
    # (linux-wallpaperengine did). "-1" because pam_env drops empty values.
    CUDA_VISIBLE_DEVICES = "-1";
  };

  offloadEnv = ''
    unset ${lib.concatStringsSep " " (lib.attrNames hidingVariables)}
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
  '';

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    ${offloadEnv}
    exec "$@"
  '';
in
{
  options.custom.power.hybridGpu = {
    enable = lib.mkEnableOption ''
      dGPU only on request on a PRIME offload laptop: EGL, Vulkan (and CUDA)
      apps use the iGPU unless started with `nvidia-offload <cmd>`, so the
      NVIDIA GPU can power off. Replaces the NixOS `nvidia-offload` script
    '';

    vulkanDrivers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
        "/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json"
      ];
      description = "Vulkan ICD manifests apps may load (the iGPU's, both architectures).";
    };

    hideCuda = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Hide CUDA devices too (`CUDA_VISIBLE_DEVICES=-1`). CUDA tools then need
        `nvidia-offload`, or `UnsetEnvironment = CUDA_VISIBLE_DEVICES` in a unit.
      '';
    };

    steamOnDgpu = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.steam.enable;
      defaultText = lib.literalExpression "config.programs.steam.enable";
      description = ''
        Run Steam and everything it starts (games, Proton) with `nvidia-offload`
        semantics, so games use the dGPU without per-game launch options. The
        dGPU then stays awake while Steam is open.
      '';
    };

    hidingVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = hidingVariables;
      description = "The session variables this module sets, for units that must unset them.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.hardware.nvidia.prime.offload.enable;
        message = "custom.power.hybridGpu needs hardware.nvidia.prime.offload.enable.";
      }
    ];

    environment.sessionVariables = hidingVariables;

    # Own script: the stock one would leave the variables above in place
    hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;
    environment.systemPackages = [ nvidia-offload ];

    # The NixOS steam module layers its own override on top of this one
    programs.steam.package = lib.mkIf cfg.steamOnDgpu (
      pkgs.steam.override { extraProfile = offloadEnv; }
    );
  };
}
