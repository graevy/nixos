{ config, lib, pkgs, ... }:

let
  me = "a";
  home = "/home/${me}/";
  vars = import ./vars.nix;
  secrets = import ./secrets.nix;

  # unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  home-manager = fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-${vars.homeManagerVersion}.tar.gz";
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
    # if i ever bother to switch to unstables
    # config = {
    #  packageOverrides = pkgs: {
    #    unstable = import unstableTarball {
    #      config = config.nixpkgs.config;
    #    };
    #  };
    # };
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
    # domain = "lol.local";
    networkmanager.enable = true;
    firewall.enable = false;
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    #proxy.default = "http://user:password@proxy:port/";
    #proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    # extraHosts = ''
    # 127
    # '';
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERM = "alacritty";
      XCURSOR_SIZE = 24;
      GTK_USE_PORTAL = "1";
    };
  };

  users.users = {
    ${me} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "torrent" "docker" "libvirtd" ]; 
      packages = with pkgs; [
      ];
    };
    # radarr = {
    #   isSystemUser = true;
    #   group = "radarr";
    #   home = "/var/lib/radarr";
    #   shell = "/run/current-system/sw/bin/nologin";
    # };
    prowlarr = {
      isSystemUser = true;
      group = "prowlarr";
      home = "/var/lib/prowlarr";
      shell = "/run/current-system/sw/bin/nologin";
    };
  };

  # virtualisation = {
  #   libvirtd.enable = true;
  #   spiceUSBRedirection.enable = true;
    # TODO
    # docker = {
    #   enable = true;
    # };
    # oci-containers = {
    #   backend = "docker";
    #   containers = {
    #     baikal = {
    #       image = "ckulka/baikal";
    #       autoStart = false;
    #       ports = [ "0.0.0.0:8080:80" ];
    #       volumes = [
    #         "/var/lib/baikal:/var/www/baikal/Specific"
    #       ];
    #       environment = {
    #         BAIKAL_DAV_AUTH_TYPE = "Digest";
    #       };
    #     };
    #   };
    # };
  # };

  users.groups = {
    mlocate = {};
    # radarr = {};
    prowlarr = {};
    torrent = {};
    headscale = {};
    libvirtd = {};
  };

  programs = {
    sway.enable = true;
    nix-ld.enable = false; # maybe
    virt-manager.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      package = pkgs.steam.override {};
    };
  };

  services = {
    # many of these are disabled in systemd.services.<service>.wantedBy below
    openssh.enable = true;
    printing.enable = true; # CUPS
    ollama.enable = false;
    thermald.enable = true; # intel cpu thermal throttling
    libinput.enable = true; # touchpad support
    tor = {
      enable = true;
      client.enable = true; # faster client port, default 9063
    };
    headscale = {
      enable = true;
      user = "${me}";
      group = "headscale";
      address = secrets.headscale_address;
      port = secrets.headscale_port;
      settings = {
        dns = {
          magic_dns = true;
          base_domain = secrets.headscale_base_domain;
          search_domains = secrets.headscale_search_domains;
        };
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };
    # torrenting services
    # radarr = {
    #   enable = true;
    #   openFirewall = true; # 7878
    #   user = "radarr";
    #   group = "radarr";
    #   dataDir = "/var/lib/radarr";
    # };
    prowlarr = {
      enable = true;
      package = pkgs.prowlarr;
    };
    jackett = {
      enable = true;
      package = pkgs.jackett;
      dataDir = "/var/lib/jackett";
      port = secrets.jackett_port;
    };
    transmission = {
      enable = true;
      openRPCPort = true;
      user = "${me}";
      settings = {
        download-dir = "${home}torrents";
        rpc-bind-address = secrets.transmission_rpc_bind_address;
	      rpc-whitelist = secrets.transmission_rpc_whitelist;
	      rpc-whitelist-enabled = false;
      };
    };
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 100;

       START_CHARGE_THRESH_BAT0 = 84; # starts-to-charge threshold
       STOP_CHARGE_THRESH_BAT0 = 85; # stops-charging threshold
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
          "kob" = { id = secrets.kob_syncthing_id; };
        };
        folders = {
          "${secrets.baby_syncthing_music_folder_id}" = {
            path = "~/Music";
            devices = [ "baby" ];
            ignorePerms = false;  # "don't sync file perms by default"
          };
          "${secrets.baby_syncthing_books_folder_id}" = {
            path = "~/Documents/books";
            devices = [ "baby" "kob" ];
            ignorePerms = false;
          };
        };
      };
    };
  };
  systemd = {
    services = {
      # this is the simplest nixos pattern i have found to (manually) lazy-load services.
      # `services.printing.enabled = false` means the unit file doesn't get created; can't `systemctl start cups`
      # note that the initial declaration is in services, not systemd.services;
      # declaring custom services here would also work, but is less stable
      printing.wantedBy = lib.mkForce [ ];
      headscale.wantedBy = lib.mkForce [ ];
      syncthing.wantedBy = lib.mkForce [ ];
      tor.wantedBy = lib.mkForce [ ];
      incrementTTL = {
        enable = true;
        description = "Increment TTL by 1 to avoid simple tunnel traffic detection";
        wantedBy = [ "multi-user.target" ];
        after = [ "sysinit.target" ];
        serviceConfig = {
	        Type = "oneshot";
	        # oh god oh fuck
          ExecStart = ''/bin/sh -c 'echo $(( $(cat /proc/sys/net/ipv6/conf/default/hop_limit) + 1 )) > /proc/sys/net/ipv6/conf/default/hop_limit && echo $(( $(cat /proc/sys/net/ipv4/ip_default_ttl) + 1 )) > /proc/sys/net/ipv4/ip_default_ttl' '';
        };
      };

      # in addition to lazy-loading services, bind them together as targets
      # these torrent services are all bound to torrent.target, meaning they stop when torrent.target stops
      # they're all wantedBy torrent.target, meaning they start when torrent.target starts.
      # systemctl [start|stop] torrent.target toggles them all
      # radarr = {
      #   bindsTo = lib.mkForce [ "torrent.target" ];
      #   wantedBy = lib.mkForce [ "torrent.target" ];
      # };
      prowlarr = {
        bindsTo = lib.mkForce [ "torrent.target" ];
        wantedBy = lib.mkForce [ "torrent.target" ];
      };
      jackett = {
        bindsTo = lib.mkForce [ "torrent.target" ];
        wantedBy = lib.mkForce [ "torrent.target" ];
      };
      transmission = {
        bindsTo = lib.mkForce [ "torrent.target" ];
        wantedBy = lib.mkForce [ "torrent.target" ];
      };

    };
    targets.torrent = {
      description = "start/stop torrents";
      wantedBy = [ ];
    };
    tmpfiles.rules = [
      "d /mnt 0755 root root"
      # "d /var/lib/radarr/ 0755 radarr radarr"
      "d /var/lib/prowlarr/ 0755 prowlarr prowlarr"
      "d /var/www/ 0755 root root"
      "d ${home}torrents 0775 ${me} torrent"
      "d ${home}writes 0700 ${me} users"
      "d ${home}Music 0775 ${me} torrent"
      #"d ${home}calendar 0755 ${me} calendar"
      "d /var/www/baikal/config 0755 root root"
      "d /var/www/baikal/Specific 0755 root root"
      "d ${home}code 0755 ${me} users"
    ];
  };

  system.activationScripts = {
    # i want root to inherit my shell, git, nvim, ssh configs...however.
    # symlinking /root/<config> to /home/me/<config> is a priv-esc risk
    # my solution is to have both me and root symlink to a third e.g. .config/shared/bashrc, drw-r--r-- root root
    # i think most people would put this in /etc, but .config is included in my home dir monorepo
    # this works well except for ssh, because openssh is stingy about its perms
    # but honestly, i just give root its own public keys, i think that's fine
    symlinkRootBashrc.text = ''
    if [ ! -L /root/.bashrc ] || [ "$(readlink -f /root/.bashrc)" != "${home}.config/shared/bashrc" ]; then
      ln -sf ${home}.config/shared/bashrc /root/.bashrc
    fi
    '';
    symlinkRootGitconfig.text = ''
    if [ ! -L /root/.gitconfig ] || [ "$(readlink -f /root/.gitconfig)" != "${home}.config/shared/gitconfig" ]; then
      ln -sf ${home}.config/shared/gitconfig /root/.gitconfig
    fi
    '';
    # TODO i think this opens my user to run arbitrary lua as root?
    symlinkRootNvim.text = ''
    if [ ! -L /root/.local/share/nvim ] || [ "$(readlink -f /root/.local/share/nvim)" != "${home}.local/share/nvim" ]; then
      mkdir -p /root/.local/share
      ln -sf ${home}.local/share/nvim /root/.local/share/nvim
    fi
    '';
  };

  xdg = {
    portal = {
      wlr = {
        enable = true;
        settings = {
          screencast = {
            output_name = "eDP-1";
            max_fps = 30;
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
          };
        };
      };
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
