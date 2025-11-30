{ pkgs, ... }: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    alacritty
    dmenu-rs
    i3status-rust
    wl-clipboard
    killall
    kdePackages.kdialog
    kdePackages.dolphin
    sops

    man-pages
    man-pages-posix

    wget
    curl
    whois
    rdap
    dig
    traceroute
    netcat
    nettools
    nmap
    openssl
    inetutils
    tmux
    mosh
    wireshark
    wireguard-tools
    caddy
    hugo

    podman
    k9s
    kubectl
    kubernetes-helm
    fluxcd

    git
    git-lfs
    git-filter-repo
    lazygit
    mlocate
    nix-tree
    nix-search-cli
    nix-inspect

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
    keepassxc

    vulkan-loader
    vulkan-tools
    mesa

    android-tools

    htop
    btop
    powertop
    dust

    grim
    slurp

    gocryptfs
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
    tree
    usbutils
    jq
    yq

    feh
    imagemagick
    viu
    tectonic # latex rendering
    mermaid-cli # mermaid diagrams

    transmission_4
    prowlarr
    jackett
    lidarr
    radarr
    yt-dlp

    firefox
    tor
    torsocks
    tor-browser
    vlc
    libreoffice
    foliate # ebooks
    anki # flash cards
    discord
    element-desktop
    telegram-desktop
    signal-desktop

    # hiding this crime for now. seems like we have to use kde or dolphin as a file chooser :l
    # (pkgs.writeTextFile {
    #   name = "yazi-choose.desktop";
    #   text =
    #     ''
    #     [Desktop Entry]
    #     Name=Yazi Chooser
    #     Icon=yazi
    #     Comment=launch yazi as a file chooser
    #     Terminal=true
    #     TryExec=yazi
    #     Exec=yazi %u --chooser-file -
    #     X-Desktop-Portal-Interfaces=org.freedesktop.impl.portal.FileChooser
    #     Type=Application
    #     MimeType=inode/directory;x-scheme-handler/file;
    #     Categories=Utility;Core;System;FileTools;FileManager;ConsoleOnly
    #     Keywords=File;Manager;Explorer;Browser;Launcher
    #     '';
    #   destination = "/share/applications/yazi-pick.desktop";
    # })

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
        ms-python.debugpy
        rust-lang.rust-analyzer
        vadimcn.vscode-lldb
        ms-vscode-remote.remote-ssh
        continue.continue
      ];
    })

    # generally i want to put languages and their associated debuggers/linters/etc in flakes instead
    # some of them want to live on the system generally, like python, which i use often as a calculator
    (python3.withPackages (ps: [ ps.debugpy ]))
    typescript
    nodejs
    jre_minimal

    # neovim wants imperative LSPs though
    gdb
    clang
    clang-tools
    lua-language-server
    rust-analyzer
    javascript-typescript-langserver

	 # ai
	 llm
	 claude-code

    # games
    winetricks
    wineWowPackages.waylandFull
    lutris
    prismlauncher
    cockatrice
  ];

  # nix documentation is so bad
  # fill this with strings
  # for each package in systemPackages, if it has a subdir matching one of these strings,
  # add it to the derivation for that string that is about to be created.
  #environment.pathsToLink = [
  #];

  fonts.packages = with pkgs; [

    nerd-fonts.dejavu-sans-mono

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

