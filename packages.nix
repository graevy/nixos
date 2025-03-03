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
    tmux
    i3status-rust
    wl-clipboard
    killall

    man-pages 
    man-pages-posix

    go
    rustc
    cargo
    python3
    typescript
    javascript-typescript-langserver
    nodejs
    gcc
    gdb

    wget
    curl
    whois
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

    ropgadget
    ghidra
    hugo
    tor

    k9s
    kubectl

    valgrind
    git
    git-lfs
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

    prowlarr
    jackett
    lidarr

    firefox
    chromium
    tor-browser
    vlc
    libreoffice
    gimp
    feh
    imagemagick
    lyx
    discord
    element-desktop
    telegram-desktop
    signal-desktop
    anki
    (vscode-with-extensions.override {
      vscodeExtensions = with
        vscode-extensions; [
	  ms-python.python
	  rust-lang.rust-analyzer
	  vadimcn.vscode-lldb
	  ms-vscode-remote.remote-ssh
	  continue.continue
	    ];
	  })

    lua-language-server
    rust-analyzer

    #unstable.rustmission
  ];

  fonts.packages = with pkgs; [

    (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })

    (pkgs.stdenv.mkDerivation {
      name = "statusbar-font";
      src = pkgs.fetchFromGitHub {
          owner = "graevy";
          repo = "newfont";
          rev = "main";
          sha256 = "1nfxzy90gbnwlv840n3zyb41xxm61q87j4rp7pm135ccynv09wks";
      };
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp $src/JetBrainsMonoRegularBar.ttf $out/share/fonts/truetype/
      '';
    })

  ];
}
