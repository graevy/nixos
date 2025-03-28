{ pkgs, ... }: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    helix
    alacritty
    dmenu-rs
    tmux
    i3status-rust
    wl-clipboard
    killall
    kdePackages.kdialog
    kdePackages.xdg-desktop-portal-kde
    kdePackages.dolphin

    man-pages 
    man-pages-posix

    go
    rustc
    cargo
    python3
    typescript
    nodejs
    gcc
    gdb

    wget
    curl
    whois
    rdap
    dig
    traceroute
    netcat
    nettools
    nmap
    inetutils
    mosh
    nginx
    wireshark
    wireguard-tools

    hugo
    tor

    k9s
    kubectl

    git
    git-lfs
    lazygit
    nix-tree
    nix-search-cli
    mlocate

    mariadb
    postgresql

    bluez
    pavucontrol

    brightnessctl
    wl-gammarelay-rs

    virt-manager
    libvirt
    qemu

    syncthing
    kid3-cli

    vulkan-loader
    vulkan-tools
    mesa

    android-tools

    htop
    btop
    powertop
    dust

    winetricks
    wineWowPackages.waylandFull
    lutris
    prismlauncher

    grim
    swappy
    slurp

    ntfs3g
    exfatprogs
    nfs-utils
    cifs-utils

    bat
    file
    zip
    unzip
    zlib
    p7zip
    ripgrep
    fd
    fzf

    feh
    imagemagick
    viu
    lyx
    tectonic # latex rendering
    mermaid-cli # mermaid diagrams

    prowlarr
    jackett
    lidarr

    firefox
    tor-browser
    vlc
    libreoffice
    gimp
    discord
    element-desktop
    telegram-desktop
    signal-desktop
    anki

    # this is the result of at least 5 hours of nixos-rebuild internals hell.
    # codelldb is a vscode extension. its binary is at /nix/store/<hash>-<name>/shared/.../codelldb,
    # and not /nix/store/<hash>-<name>/bin/codelldb.
    # this means the binary is not automatically linked in /run/current-system/sw/bin by nixos-rebuild,
    # and is therefore not PATH-accessible. so of all the solutions i tried,
    # this is the only one that declaratively met the criteria of:
    # idempotently appending to PATH, presenting a binary (not a wrapper), readable, and near the package definition
    vscode-extensions.vadimcn.vscode-lldb.adapter
    # i also went for this to manually extract the adapter
    #(pkgs.runCommand "symlink-codelldb" { } ''
    #  mkdir -p $out/bin
    #  ln -s ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $out/bin/codelldb
    #'')
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
	      ms-python.python
	      rust-lang.rust-analyzer
        # idk if defining this outside of this block matters yet
	      #vadimcn.vscode-lldb
	      ms-vscode-remote.remote-ssh
	      continue.continue
	    ];
	  })

    lua-language-server
    rust-analyzer
    javascript-typescript-langserver
  ];

  # nix documentation is so bad
  # fill this with strings
  # for each package in systemPackages, if it has a subdir matching one of the strings,
  # add it to the derivation for that string that is about to be created.
  #environment.pathsToLink = [
  #];

  fonts.packages = with pkgs; [

    (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })

    (pkgs.stdenv.mkDerivation {
      name = "statusbar-font";
      src = pkgs.fetchFromGitHub {
          owner = "graevy";
          repo = "newfont";
          rev = "main";
          sha256 = "14194f7fxmkdqfcbx9qr2mnfkgp4s84jlzissmb5h12viv2ca8cq";
      };
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp $src/JetBrainsMonoRegularBar.ttf $out/share/fonts/truetype/
      '';
    })

  ];
}
