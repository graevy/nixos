{ config, lib, pkgs, ... }:

let
  vars = import ./vars.nix;
  nixpkgs = import <nixpkgs> {};
in
{
  imports = [ ./hardware-configuration.nix ./packages.nix ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      # for 25.11 release
      # will eventually want to switch to https://github.com/RefindPlusRepo/RefindPlus
      # https://github.com/NixOS/nixpkgs/pull/414394#issuecomment-2949492057
      # refind = {
      #   enable = true;
      #   version = "stable";
      # };
    };
    kernel.sysctl = {
      # default value is 60
      # i really don't want to use swap unless i'm about to oom
      "vm.swappiness" = 5;
    };
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8*1024; # megs
    options = [ "discard" ];
    # encrypts ram contents so they don't leak to disk
    randomEncryption.enable = true;
  }];

  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs = {
    # if i ever bother to switch to unstables
    config = {
      allowUnfree = true;
    };
    # overlays = [
      # https://github.com/NixOS/nixpkgs/issues/371837
      # (final: prev: { 
      #   jackett = prev.jackett.overrideAttrs { doCheck = false; }; 
      # })
    # ];
  };

  home-manager = {
    backupFileExtension = "backup";
    users = {
      "${vars.me}" = import ./home-manager-a.nix;
      # lol
      root = import ./home-manager-a.nix;
    };
  };

  # secrets manager, input from flake
  sops = {
    defaultSopsFile = ./secrets/secrets.json;
    defaultSopsFormat = "json";
    
    # maybe wants a separate key eventually
    age.keyFile = "${vars.homeDir}.config/sops/age/keys.txt";
    
    secrets = {
      # TODO
      # gocryptfs-key = { format = "json"; };
    };
    templates = {};
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
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERM = "alacritty";
      XCURSOR_SIZE = "24";
      GTK_USE_PORTAL = "1";
      # default to wayland
      NIXOS_OZONE_WL = "1";
    };
  };

  users.users = {
    ${vars.me} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "torrent" "docker" "libvirtd" ]; 
      # packages = with pkgs; [
      # ];
    };
  };

  # virtualisation = {
  #   libvirtd.enable = true;
  #   spiceUSBRedirection.enable = true;
  #   docker = {
  #     enable = true;
  #   };
  #   oci-containers = {
  #     backend = "docker";
  #     containers = {}
  #   };
  # };

  users.groups = {
    mlocate = {};
    headscale = {};
    libvirtd = {};
  };

  programs = {
    sway = {
      enable = true;
    };
    nix-ld.enable = true; # maybe
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    virt-manager.enable = true;
  };

  services = {

    dbus.enable = true;     # likely doesn't need to be explicitly enabled because of sway
    thermald.enable = true; # intel cpu software thermal throttling
    libinput.enable = true; # touchpad support
    upower.enable = true;   # so that apps can query power status. privacy meh, performance optimization for firefox yay

    # many of these are disabled in systemd.services.<service>.wantedBy below
    openssh.enable = true;
    printing.enable = false; # CUPS
    ollama.enable = false;
    tor = {
      enable = true;
      client.enable = true; # faster client port, default 9063
    };
    headscale = {
      enable = true;
      user = "${vars.me}";
      group = "headscale";
      address = "127.0.0.1";
      port = 64081;
      settings = {
        dns = {
          magic_dns = true;
          base_domain = "very.local";
          search_domains = [];
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
  };
  systemd = {
    services = {
      # this is the simplest nixos pattern i have found to (manually) lazy-load services.
      # `services.printing.enabled = false` means the unit file doesn't get created; can't `systemctl start cups` without this
      # note that the initial declaration is in services, not systemd.services;
      # declaring custom services here would also work, but is less stable
      printing.wantedBy = lib.mkForce [ ];
      headscale.wantedBy = lib.mkForce [ ];
      tor.wantedBy = lib.mkForce [ ];
      incrementTTL = {
        enable = true;
        description = "Increment TTL by 1 to avoid simple tunnel traffic detection";
        wantedBy = [ "multi-user.target" ];
        after = [ "sysinit.target" ];
        serviceConfig = {
          Type = "oneshot";
          # oh god oh fuck
          ExecStart = lib.concatStringsSep " " [
            "/bin/sh" "-c"
            "'read -r ipv6 < /proc/sys/net/ipv6/conf/default/hop_limit &&"
            "echo $((ipv6 + 1)) > /proc/sys/net/ipv6/conf/default/hop_limit &&"
            "read -r ipv4 < /proc/sys/net/ipv4/ip_default_ttl &&"
            "echo $((ipv4 + 1)) > /proc/sys/net/ipv4/ip_default_ttl'"
          ];
        };
      };
    };
    user.services = {
      # xdg-desktop-portal needs user $PATH to open applications correctly
      # https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
      xdg-desktop-portal = {
        serviceConfig = {
          Environment = [
            ''PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%i/bin:$PATH''
          ];
        };
      };
    };
    tmpfiles.rules = [
      "d /mnt 0755 root root"
      "d /var/www/ 0755 root root"
      "d ${vars.homeDir}writes 0700 ${vars.me} users"
      "d ${vars.homeDir}Music 0775 ${vars.me} torrent"
      "d ${vars.homeDir}code 0755 ${vars.me} users"

      # i want root to inherit my shell, git, nvim, ssh configs...however.
      # symlinking /root/<config> to /home/me/<config> is a priv-esc risk
      # my solution is to have both me and root symlink to a third e.g. .config/shared/bashrc, drw-r--r-- root root
      # i think most people would put this in /etc, but .config is included in my home dir monorepo
      # this works well except for ssh, because openssh is stingy about its perms
      "L /root/.bashrc - - - - ${vars.homeDir}.config/shared/bashrc"
      "L /root/.gitconfig - - - - ${vars.homeDir}.config/shared/gitconfig"
      # TODO priv-esc
      "L /root/.local/share/nvim - - - - ${vars.homeDir}.local/share/nvim"
    ];
  };

  system.activationScripts = {
    # https://www.rodsbooks.com/refind/themes.html
    # set to a 1x1 black pixel so that the background isn't 7F7F7F fullbright grey
    refindBlackBackground = {
      text = ''${pkgs.imagemagick}/bin/magick -size 1x1 canvas:black /boot/efi/refind/background.png'';
      # deps = [ "bootloader" ];
    };
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        # kdePackages.xdg-desktop-portal-kde # maybe later idk
        xdg-desktop-portal-wlr
      ];
      config = {
        sway = {
          # setting sway.enable by default sets this to gtk
          # wlr has features, gtk has compatibility
          # try wlr first, then fallback to gtk
          default = lib.mkForce [ "wlr" "gtk" ];
          "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
          "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        };
      };
      xdgOpenUsePortal = true;
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
    mime = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/file" = "org.kde.dolphin.desktop";
        "inode/directory" = "org.kde.dolphin.desktop";
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

  # don't touch it
  system.stateVersion = "24.11"; # don't you dare
}

