recovery model is:
  - pull this repo
  - pull stateful sources:
    - home dir / [dotfiles](https://github.com/graevy/dotfiles)
    - `secrets.nix`
    - `/var/lib`
    - `/etc/NetworkManager` maybe?
  - `su -c 'nixos-rebuild switch'`
