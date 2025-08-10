{ lib, pkgs, config, ... }:
let
  vars = import ./vars.nix;
  secrets = import ./secrets.nix;
in
{
  home = {
    stateVersion = "${vars.homeManagerVersion}";
  };
  programs = {
    git = {
      enable = true;
      userName = "avery";
      userEmail = "avry@pm.me";
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = false;
    };
  };
  xdg = {
    configFile."nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/nvim/";
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
}
