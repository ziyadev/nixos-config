{ config, pkgs, lib, inputs, ... }:

# Host-specific settings only. The Omarchy desktop stack itself (Hyprland +
# uwsm + Quickshell + sddm + fonts + the full omarchy-base.packages list) is
# in ../../modules/omarchy.nix, imported by flake.nix alongside this file.
{
  imports = [
    # Generate this on the target laptop with:
    #   sudo nixos-generate-config --dir ./hosts/laptop
    # then copy the resulting hardware-configuration.nix here.
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop"; # change to whatever you want

  # --- Bootloader -----------------------------------------------------
  # Real Omarchy uses limine + limine-snapper-sync for boot-time Btrfs
  # snapshot rollback. NixOS's own generations (visible in this same
  # systemd-boot menu, roll back with `nixos-rebuild switch --rollback`)
  # cover that use case natively — not worth reintroducing limine/snapper
  # for it. Swap to boot.loader.grub if the target machine needs BIOS boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Networking -------------------------------------------------------
  networking.networkmanager.enable = true;
  networking.firewall.enable = true; # NixOS-native equivalent of ufw

  # --- Time / locale ------------------------------------------------------
  time.timeZone = "Etc/UTC"; # set to your real timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Users ----------------------------------------------------------
  users.users.ziyadev = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true; # chromium, obsidian, moonlight-qt, etc.

  system.stateVersion = "24.11";
}
