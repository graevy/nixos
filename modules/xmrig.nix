{ pkgs, lib, config, ... }:

let
  pkgsCuda = import pkgs.path {
    inherit (pkgs) system;
    config = pkgs.config // {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  cuda-loader = "${pkgsCuda.xmrig-cuda}/lib/libxmrig-cuda.so";

mine = pkgs.writeShellApplication {
  name = "mine";
  text = ''
    cpu_intensity=''${1:-50}
    gpu_intensity=''${2:-50}
    address=''${XMR_ADDRESS:?error: XMR_ADDRESS unset}
    pool=''${XMR_POOL:?error: XMR_POOL unset}

    gpu_default_watts=$( \
      /run/wrappers/bin/nvidia-smi \
        --query-gpu=power.default_limit \
        --format=csv,noheader,nounits )
    gpu_watts=$( awk "BEGIN { printf \"%d\", $gpu_default_watts * $gpu_intensity / 100 }" )
    echo "setting GPU power limit to ''${gpu_watts}W (default: ''${gpu_default_watts}W, intensity: ''${gpu_intensity}%)"
    /run/wrappers/bin/nvidia-smi -pl "$gpu_watts"

    cleanup() {
      echo "resetting power limits..."
      /run/wrappers/bin/nvidia-smi -pl "$gpu_default_watts"
      echo "GPU reset to ''${gpu_default_watts}W"
    }
    trap cleanup EXIT

    echo "starting xmrig: pool=$pool cpu_intensity=''${cpu_intensity}% gpu_intensity=''${gpu_intensity}%"
    /run/wrappers/bin/xmrig \
      --url "$pool" \
      --user "$address" \
      --pass "nixos-rig" \
      --coin monero \
      --cpu-max-threads-hint "$cpu_intensity" \
      --cuda \
      --cuda-loader "${cuda-loader}" \
      --http-host 127.0.0.1 \
      --http-port 3334 \
      --donate-level 1 \
      --randomx-init 1 &

    xmrig_pid=$!
    wait "$xmrig_pid"
  '';
};

in {
  security.wrappers.xmrig = {
    source = "${pkgsCuda.xmrig}/bin/xmrig";
    owner = "root";
    group = "root";
    capabilities = "cap_sys_rawio,cap_sys_nice+ep";
  };

  security.wrappers.nvidia-smi = {
    source = "/run/current-system/sw/bin/nvidia-smi";
    owner = "root";
    group = "root";
    setuid = true;
  };

  environment.systemPackages = [ mine ];
}

