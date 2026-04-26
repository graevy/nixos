{ lib, pkgs, config, ... }:
let
  vars = import ./vars.nix;
in
{
  home.stateVersion = "${vars.homeManagerVersion}";

  xdg = {
    configFile."nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.homeDir}.local/share/nvim/";
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/file" = "org.kde.dolphin.desktop";
        "inode/directory" = "org.kde.dolphin.desktop";
        "image/jpeg" = "feh.desktop";
        "image/png" = "feh.desktop";

        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        # "x-scheme-handler/mailto";
        #
        # "video" = "vlc.desktop";
        # "audio" = "vlc.desktop";
        #"text/calendar"
      };
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # sops.secrets."gocryptfs-key" = {
  #   sopsFile = ./secrets.yaml;
  #   mode = "0400";
  # };

  # home.fileSystems = {
  #   "${vars.homeDir}test" = {
  #     device = "${vars.homeDir}test.encrypted";
  #     fsType = "fuse.gocryptfs";
  #     options = [
  #       "rw"
  #       "noatime"
  #       "allow_other"
  #       "exec"
  #       "x-systemd.requires=graphical-session.target"
  #       # TODO: better model for home-manager sops?
  #       # "extpass=cat ${sops.secrets.gocryptfs-key.path}"
  #     ];
  #   };
  # };

  programs = {
    git = {
      enable = true;
		settings.user = {
			name = "avery";
			email = "avery@cute.tg";
		};
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = false;
    };
  };

  services = {
    syncthing = {
      enable = true;
      # override *WebUI* devices/folders
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
		    "home" = { id = "TAJOPPQ-M4CXQQL-MCCN7D4-Q3LEBTI-MXPFKEC-EQL2I6C-YC2A2MD-2KRB7QD"; };
			 "very" = { id = "HN7JQZO-HY4SYNO-F5ZOIZI-5EBCBSR-BFHTOFX-RSVX5RV-LVWUCYR-RQYJRAX"; };
          "baby" = { id = "QA46X3F-UHHIGX3-4H4KG5Y-ULQBBKL-4VRDYUF-KRX26YZ-AMXCO3F-NYJSXQO"; };
          "kob" = { id = ""; };
        };
        folders = {
          "j0z43-s5odd" = {
            path = "${vars.homeDir}Music";
            devices = [ "home" "very" "baby" ];
            ignorePerms = false;  # "don't sync file perms by default"
          };
          "books-42069" = {
            path = "${vars.homeDir}Documents/books";
            devices = [ "home" "very" "baby" "kob" ];
            ignorePerms = false;
          };
        };
      };
    };
  };

  systemd.user = {
    services = {
	   syncthing.Install.WantedBy = lib.mkForce [ ];
      prowlarr = {
        Unit = {
          Description = "Prowlarr";
          After = [ "network.target" ];
          BindsTo = [ "torrent.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=%h/.local/share/prowlarr";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "torrent.target" ];
        };
      };

      # jackett = {
      #   Unit = {
      #     Description = "Jackett";
      #     After = [ "network.target" ];
      #     BindsTo = [ "torrent.target" ];
      #   };
      #   Service = {
      #     Type = "simple";
      #     ExecStart = "${pkgs.jackett}/bin/Jackett --NoRestart --DataFolder %h/.local/share/jackett --Port 9697";
      #     Restart = "on-failure";
      #   };
      #   Install = {
      #     WantedBy = [ "torrent.target" ];
      #   };
      # };

      transmission = {
        Unit = {
          Description = "Transmission BitTorrent Daemon";
          After = [ "network.target" ];
          BindsTo = [ "torrent.target" ];
        };
        Service = {
          Type = "simple";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.transmission_4}/bin/transmission-daemon"
          "-f"
          "--config-dir %h/.local/share/transmission"
          "-w %h/.local/share/transmission/torrents"
          "--bind-address-ipv4 127.0.0.1"
          "--rpc-bind-address 127.0.0.1"
        ];
          ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "torrent.target" ];
        };
      };
    };

    targets = {
      torrent = {
        Unit = {
          Description = "toggle torrent services via `systemctl --user [start|stop] torrent.target`";
        };
        Install.WantedBy = [ "" ];
      };
    };

    tmpfiles.rules = [
      "d %h/.local/share/transmission 0755 - - -"
      "d %h/.local/share/prowlarr 0755 - - -"
      "d %h/.local/share/jackett 0755 - - -"
		# "d %h/.local/state/nix/profiles 0755 - - -"

		"d ${vars.homeDir}code 0755 ${vars.me} users"
		"d ${vars.homeDir}writes 0700 ${vars.me} users"
		"d ${vars.homeDir}Music 0755 ${vars.me} users"
		"d ${vars.homeDir}Pictures 0755 ${vars.me} users"

      "L %h/torrents - - - - %h/.local/share/transmission/torrents"
    ];
  };
}

