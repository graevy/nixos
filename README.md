recovery model is:
  - pull this repo
  - pull [dotfiles](https://github.com/graevy/dotfiles)
  - pull stateful sources:
    - home dir (sops-nix should eventually replace this with a decryption step)
    - `/var/lib` maybe
    - `/etc/NetworkManager` maybe
  - `su -c 'nixos-rebuild switch --flake /etc/nixos#a'`

