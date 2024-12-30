{ pkgs, config, ... }: {
  # Enable graphics support
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
    ];
  };

  hardware.nvidia = {
    # Enable modesetting, required for proper GPU operation
    modesetting.enable = true;

    # NVIDIA power management options
    # Setting this to false might prevent issues with sleep and wake
    powerManagement.enable = false;  # Experimental; enable if you encounter issues

    # Fine-grained power management; turns off the GPU when not in use
    powerManagement.finegrained = false;  # Only for Turing or newer GPUs, experimental

    # Enable the open-source NVIDIA kernel module (experimental support)
    open = false;  # Recommended to keep disabled for stability

    # Enable NVIDIA settings menu accessible via `nvidia-settings`
    nvidiaSettings = true;

    # Specify the NVIDIA driver package version; use as needed for your GPU
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    prime = {
      # Enable offloading to NVIDIA GPU
      offload = {
        enable = true;  # Enable offloading of rendering to NVIDIA
        enableOffloadCmd = true;  # Command support for offloading
      };

      # Specify the Bus IDs for your GPUs; make sure they match your system's hardware
      intelBusId = "PCI:0:2:0";   # Intel GPU bus ID
      nvidiaBusId = "PCI:1:0:0";  # NVIDIA GPU bus ID
      # amdgpuBusId = "PCI:54:0:0";  # Uncomment this if you have an AMD GPU
    };
  };
}
