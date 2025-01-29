{ config, lib, pkgs, ... }: {
  home.stateVersion = "${config.homeManagerVersion}";
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
      plugins = with pkgs.vimPlugins; [
        lazy-nvim
      ];
    };
  };
}
