recovery model is:
  - pull this repo
  - pull stateful sources:
    - [dotfiles](https://github.com/graevy/dotfiles)
    - `/var/lib`
    - `/etc/NetworkManager` maybe?
  - `su -c 'nixos-rebuild switch'`
