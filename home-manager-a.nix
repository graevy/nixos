{ lib, pkgs, config, osConfig, ... }: 
{
  home = {
    stateVersion = "24.11";
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
    portal = {
      enable = true;
      config = {
        common = {
          default = [
            # TODO: this kindof competes with the mimeApps.defaultApplications x-scheme-handler/file declaration
            # not sure how they interact. i built yazi-choose to use a rust tui file chooser because dolphin kept segfaulting
            # lots of things don't play well with xdg portals, particularly firefox.
            # there's not enough standardization other than like, kde (dolphin) and gtk (nautilus & forks) defaults.
            # so i'm stuck with dolphin unless i deep-dive this again
            "org.freedesktop.impl.portal.FileChooser=yazi-choose"
            "KDE"
          ];
        };
      };
      extraPortals = with pkgs; [ kdePackages.xdg-desktop-portal-kde ];
      xdgOpenUsePortal = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/file" = "org.kde.dolphin.desktop";
        "inode/directory" = "alacritty.desktop";
        "image/jpeg" = "feh.desktop";
        "image/png" = "feh.desktop";

        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        # "x-scheme-handler/mailto";

        "video" = "vlc.desktop";
        "audio" = "vlc.desktop";
        #"text/calendar"
      };
    };
  };
}
