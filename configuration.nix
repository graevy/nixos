{ config, lib, pkgs, vars, ... }:

{
  boot = {
	 loader = {
		systemd-boot.enable = true;
		efi = {
		  canTouchEfiVariables = true;
		  efiSysMountPoint = "/boot";
		};
		# for 25.11?
		# will eventually want to switch to https://github.com/RefindPlusRepo/RefindPlus
		# https://github.com/NixOS/nixpkgs/pull/414394#issuecomment-2949492057
		# refind = {
		#	 enable = true;
		#	 version = "stable";
		# };
		};

		kernel.sysctl = {

		  "vm.swappiness" = 60; # defaults to 60

		  # 2.5gb hugepages for mining
		  "vm.nr_hugepages" = 1280;
		};

		# specifically for passive mining
		kernelModules = [ "msr" ];
	};

  swapDevices = [{
	 device = "/var/lib/swapfile";
	 size = 8*1024; # megs
	 options = [ "discard" ];
	 # encrypts ram contents so they don't leak to disk. appears to cause crashes?
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
	 overlays = [
		# # https://github.com/NixOS/nixpkgs/issues/371837
		# (final: prev: { 
		#  jackett = prev.jackett.overrideAttrs { doCheck = false; }; 
		# })
	 ];
  };

  home-manager = {
	 backupFileExtension = "backup";
	 users = {
		"${vars.me}" = import (./. + "/home-manager-${vars.me}.nix");
		root = import (./. + "/home-manager-${vars.me}.nix");
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
#	console = {
#	  font = "DejaVuSansMono";
#	  keyMap = "us";
#	  useXkbConfig = true; # use xkb.options in tty.
#	};

  networking = {
	 hostName = "${vars.hostName}";
	 networkmanager.enable = true;
	 firewall.enable = false;
  };

  hardware = {
    graphics.enable = true;
	 graphics.enable32Bit = true;
	 bluetooth.enable = true;
	 nvidia = { 
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  environment = {
	 variables = {
		EDITOR = "nvim";
		VISUAL = "nvim";
		TERM = "alacritty";
		XCURSOR_SIZE = 24;
		# desktop portals
		GTK_USE_PORTAL = 1;
		GTK_THEME="Dracula";

		# need to tell java apps using awt that my windows are "nonreparenting" because tiling wm
		_JAVA_AWT_WM_NONREPARENTING = 1;
	 };
  };

  users.users = {
	 ${vars.me} = {
		isNormalUser = true;
		extraGroups = [ "wheel" "networkmanager" "torrent" "docker" "libvirtd" ]; 
		# packages = with pkgs; [ ];
	 };
  };

  # virtualisation = {
  #	libvirtd.enable = true;
  #	spiceUSBRedirection.enable = true;
  #	docker = {
  #	  enable = true;
  #	};
  #	oci-containers = {
  #	  backend = "docker";
  #	  containers = {}
  #	};
  # };

  users.groups = {
	 mlocate = {};
	 headscale = {};
	 libvirtd = {};
  };

  programs = {
	 nix-ld.enable = true; # maybe
	 direnv = {
		enable = true;
		nix-direnv.enable = true;
	 };
	 virt-manager.enable = true;
	 steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

  };

  services = {
    xserver = {
	   enable = true;
      videoDrivers = [ "nvidia" ];
      windowManager.i3.enable = true;
      displayManager.startx.enable = true;
	 };

	 dbus.enable = true;		 # likely doesn't need to be explicitly enabled?

	 # many of these are disabled via systemd.services.<service>.wantedBy below
	 openssh.enable = true;
	 printing.enable = true; # CUPS
	 ollama.enable = false;
	 # userspace-policing oom killer daemon sitting ahead of the kernelspace's
	 earlyoom = {
      enable = true; freeMemThreshold = 5; freeSwapThreshold = 5; # percentage
    };
	 # link-local mDNS discovery
	 avahi = {
      enable = true; nssmdns4 = true; openFirewall = true;
    };
	 tor = {
		enable = true; client.enable = true; # faster client port, default 9063
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
			 base_domain = "${vars.hostName}.local";
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
    monero = {
      enable = true;
		prune = true;
		rpc = {
		  address = "127.0.0.1";
		  port = 18081;
		  user = "monero";
		  password = "monero";
		};

      # Extra monerod flags
      extraConfig = ''
        db-sync-mode=safe
        no-igd=1
      '';

      dataDir = "/var/lib/monero";
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
		avahi.wantedBy = lib.mkForce [ ];

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

    # xdg-desktop-portal needs user $PATH to open applications correctly
    # https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
	 user.services.xdg-desktop-portal.serviceConfig.Environment = [
				''PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%i/bin:$PATH''
    ];

	 tmpfiles.rules = [
		"d /mnt 0755 root root"
		"d /var/www/ 0755 root root"

		# root inherits my configs
		# e.g. /home/a/.bashrc must be `drw-r--r-- root root` to avoid priv-esc on root shell
		# this works well except for ssh, nvim...things i try not to do as root anyway
		"L /root/.bashrc - - - - ${vars.homeDir}.bashrc"
		"L /root/.gitconfig - - - - ${vars.homeDir}.gitconfig"
		"L /root/.local/share/nvim - - - - ${vars.homeDir}.local/share/nvim"
	 ];
  };

  system.activationScripts = {
	 # https://www.rodsbooks.com/refind/themes.html
	 # set to a 1x1 black pixel so that the background isn't 7F7F7F fullbright grey
	 refindBlackBackground = {
		text = ''${pkgs.imagemagick}/bin/magick -size 1x1 canvas:black /boot/EFI/refind/background.png'';
		# deps = [ "bootloader" ];
	 };
  };

  xdg = {
	 portal = {
		enable = true;
		extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
		config.common.default = [ "gtk" ];
		xdgOpenUsePortal = true;
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

  # don't touch it
  system.stateVersion = "24.11"; # don't you dare
}

