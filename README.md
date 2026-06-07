for fresh install from nixos-minimal iso:

    get root, make partitions with fdisk, mount root&boot, cd /mnt
    mkdir etc && cd etc
    nix-shell -p git, git clone https://github.com/graevy/nixos, cd nixos
    nixos-install --flake .#a
    exit root
    proceed to dotfiles
    if recovering, pull stateful sources:
        home dir (sops-nix should eventually replace this with a decryption step)
        /var/lib maybe
        /etc/NetworkManager maybe
