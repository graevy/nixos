# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  me = "a";
  home = "/home/${me}/";
  secrets = import ./secrets.nix;

  homeManagerVersion = "24.11"; # TODO: ssot for home-manager.nix
  
  #unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  home-manager = fetchTarball "https://github.com/nix-community/home-manager/archive/release-${homeManagerVersion}.tar.gz";
  nixpkgs = import <nixpkgs> {};
in
{
  imports =
    [ 
      ./hardware-configuration.nix
      ./packages.nix
      (import "${home-manager}/nixos")
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs = {
    #config = {
    #  packageOverrides = pkgs: {
    #    unstable = import unstableTarball {
    #      config = config.nixpkgs.config;
    #    };
    #  };
    #};
    overlays = [
      # https://github.com/NixOS/nixpkgs/issues/371837
      (final: prev: { 
        jackett = prev.jackett.overrideAttrs { doCheck = false; }; 
      })
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    users = {
      "${me}" = import ./home-manager-a.nix;
      root = import ./home-manager-a.nix;
    };
  };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
# TODO
#  console = {
#    font = "DejaVuSansMono";
#    keyMap = "us";
#    useXkbConfig = true; # use xkb.options in tty.
#  };

  networking = {
    hostName = "very";
    networkmanager.enable = true;
    firewall.enable = false;
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    #proxy.default = "http://user:password@proxy:port/";
    #proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    extraHosts = ''
    127
    '';
  };

  environment = {
    etc = {
    };
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERM = "alacritty";
      XCURSOR_SIZE = 24;
    };
  };

  users.users = {
    ${me} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "torrent" "docker" ]; 
      packages = with pkgs; [
      ];
    };
    #nginx.extraGroups = [ "acme" ];
    radarr = {
      isSystemUser = true;
      group = "radarr";
      home = "/var/lib/radarr";
      shell = "/run/current-system/sw/bin/nologin";
    };
    prowlarr = {
      isSystemUser = true;
      group = "prowlarr";
      home = "/var/lib/prowlarr";
      shell = "/run/current-system/sw/bin/nologin";
    };
  };

  virtualisation = {
    docker = {
      enable = true;
    };
    oci-containers = {
      backend = "docker";
      containers = {
        baikal = {
          image = "ckulka/baikal";
          autoStart = true;
          ports = [ "0.0.0.0:8080:80" ];
          volumes = [
            "/var/lib/baikal:/var/www/baikal/Specific"
          ];
          environment = {
            BAIKAL_DAV_AUTH_TYPE = "Digest";
          };
        };
      };
    };
  };

  users.groups = {
    mlocate = {};
    radarr = {};
    prowlarr = {};
    torrent = {};
  };

  services = {
    openssh.enable = true;
    printing.enable = false; # CUPS
    libinput.enable = true; # Touchpad support
    tailscale.enable = true;
    ollama.enable = false;
    thermald.enable = true; # intel cpu thermal throttling
    radarr = {
      enable = true;
      openFirewall = true; # 7878
      user = "${me}";
      group = "radarr";
      dataDir = "/var/lib/radarr";
    };
    prowlarr = {
      enable = true;
      package = pkgs.prowlarr;
    };
    jackett = {
      enable = true;
      package = pkgs.jackett;
      dataDir = "/var/lib/jackett";
      port = 9697; # default
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };
    transmission = {
      enable = true;
      openRPCPort = true;
      user = "${me}";
      settings = {
        download-dir = "${home}torrents";
        rpc-bind-address = "127.0.0.1";
	rpc-whitelist = "127.0.0.1";
	rpc-whitelist-enabled = false;
      };
    };
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 100;

       START_CHARGE_THRESH_BAT0 = 70; # starts-to-charge threshold
       STOP_CHARGE_THRESH_BAT0 = 80; # stops-charging threshold
      };
    };
    syncthing = {
      enable = true;
      group = "users";
      user = "${me}";
      dataDir = "/var/lib/syncthing/";
      configDir = "${home}.config/syncthing";
      # override *WebUI* devices/folders
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          "baby" = { id = secrets.baby_syncthing_id; };
        };
        folders = {
          "j0z43-s5odd" = {
            path = "~/Music";
            devices = [ "baby" ];
            ignorePerms = false;  # By default, Syncthing doesn't sync file permissions
          };
        };
      };
    };
  };

  system.activationScripts = {
    symlinkRootBashrc.text = ''
    if [ ! -L /root/.bashrc ] || [ "$(readlink -f /root/.bashrc)" != "${home}.bashrc" ]; then
      ln -sf ${home}.bashrc /root/.bashrc
    fi
    '';
    symlinkRootDotssh.text = ''
    if [ ! -L /root/.ssh ] || [ "$(readlink -f /root/.ssh)" != "${home}.ssh" ]; then
      ln -sf ${home}.ssh /root/.ssh
    fi
    '';
    symlinkRootGitconfig.text = ''
    if [ ! -L /root/.gitconfig ] || [ "$(readlink -f /root/.gitconfig)":wq != "${home}.gitconfig" ]; then
      ln -sf ${home}.gitconfig /root/.gitconfig
    fi
    '';
    symlinkRootNvim.text = ''
    if [ ! -L /root/.local/share/nvim ] || [ "$(readlink -f /root/.local/share/nvim)" != "${home}.local/share/nvim" ]; then
      mkdir -p /root/.local/share
      ln -sf ${home}.local/share/nvim /root/.local/share/nvim
    fi
    '';
  };

  fileSystems = {
    "/var/lib/prowlarr" = {
      device = "{pkgs.prowlarr}";
      options = [ "bind" "rw" ];
      fsType = "none";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /mnt 0755 root root"
      "d /var/lib/radarr/ 0755 radarr radarr"
      "d /var/lib/prowlarr/ 0755 prowlarr prowlarr"
      "d /var/www/ 0755 root root"
      "d /var/www/baikal/config 0755 root root"
      "d /var/www/baikal/Specific 0755 root root"
      "d ${home}torrents 0775 ${me} torrent"
      "d ${home}writes 0700 ${me} users"
      "d ${home}Music 0775 ${me} torrent"
      "d ${home}calendar 0755 ${me} calendar"
    ];
    services = {
      # TODO
      #autoSway = {
      #  enable = true;
      #  description = "Start sway on login";
      #  wants = [ "graphical.target" ];
      #  after = [ "graphical.target" ];
      #  serviceConfig = {
      #    Type = "simple";
      #    Restart = "always";
      #    User = "%u";
      #    PAMName = "login";
      #    Environment = ''"XDG_RUNTIME_DIR=/run/user/%U"'';
      #    ExecStart = ''/bin/sh -c 'sway' '';
      #  };
      #};
      incrementTTL = {
        enable = true;
        description = "Increment TTL by 1 to avoid tunnel traffic detection";
        wantedBy = [ "multi-user.target" ];
        after = [ "sysinit.target" ];
        serviceConfig = {
	        Type = "oneshot";
	        # oh god oh fuck
          ExecStart = ''/bin/sh -c 'echo $(( $(cat /proc/sys/net/ipv6/conf/default/hop_limit) + 1 )) > /proc/sys/net/ipv6/conf/default/hop_limit && echo $(( $(cat /proc/sys/net/ipv4/ip_default_ttl) + 1 )) > /proc/sys/net/ipv4/ip_default_ttl' '';
        };
      };
    };
    user.services = {
      
    };
  };

  xdg.portal.wlr.enable = true;

  programs = {
    sway.enable = true;
    nix-ld.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      package = pkgs.steam.override {};
    };
  };

  security.rtkit.enable = true;

  hardware.bluetooth.enable = true;

  hardware.graphics= {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-sdk
    ];  
  };


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # don't touch it
  system.stateVersion = "24.11"; # don't you dare
}
