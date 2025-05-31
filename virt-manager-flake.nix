# haven't used this yet, grabbed it from https://www.reddit.com/r/NixOS/comments/177wcyi/best_way_to_run_a_vm_on_nixos/k4vok4n/
{config, pkgs, ... }:
{
  programs.dconf.enable = true;
  users.users.gcis.extraGroups = [ "libvirtd" ];
  environment.systemPackages = with pkgs; [ virt-manager virt-viewer spice spice-gtk spice-protocol win-virtio win-spice gnome.adwaita-icon-theme ];
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
