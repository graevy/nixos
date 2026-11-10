for fresh install from nixos-minimal iso:

- `sudo su`, `lsblk -af`, `fdisk <disk>`, [make partitions](https://nixos.wiki/wiki/NixOS_Installation_Guide) (boot part size +1G probably)
- `nmcli d wifi con <network> password <password>`
- `nix-shell -p git cryptsetup`
- `cryptsetup luksFormat /dev/<nixos part>`, `cryptsetup open /dev/<nixos part> cryptroot`
- `mkfs.fat -F 32 -n boot /dev/<boot part>`, `mkfs.btrfs -L nixos /dev/mapper/cryptroot` or whatever fs
- `nix-shell -p git`, `cd /mnt/etc/nixos`, `git clone https://github.com/graevy/nixos .`
- `nixos-generate-config --root /mnt`
- `git add -A`, `git add -f hardware-configuration.nix`
- `nixos-install --flake .#<HOSTNAME>` not user, hostname
- `git restore --staged hardware-configuration.nix`
- `exit` root
- `cd /home/<user>/crypt.cipher && gocryptfs -init`
- proceed to [dotfiles](https://github.com/graevy/dotfiles)
- if recovering, pull stateful sources:
    home dir (sops-nix should eventually replace this with a decryption step)
    /var/lib maybe
    /etc/NetworkManager maybe

