{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Generate this on the target laptop with:
    #   sudo nixos-generate-config --dir ./hosts/laptop
    # then copy the resulting hardware-configuration.nix here.
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop"; # change to whatever you want

  # --- Bootloader ---------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Networking -----------------------------------------------------
  networking.networkmanager.enable = true;

  # --- Time / locale ----------------------------------------------------
  time.timeZone = "Etc/UTC"; # set to your real timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Users --------------------------------------------------------------
  users.users.ziyadev = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # --- Hyprland -------------------------------------------------------
  # Omarchy's shell/bar is its own QML-based desktop shell layered on top of
  # Hyprland (see config/omarchy/shell.json + config/omarchy/plugins) and is
  # not packaged for NixOS. This gives you vanilla Hyprland; the bar/theme
  # layer needs to be replaced (waybar, ags, quickshell, etc.) or rebuilt.
  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # --- Input method (fcitx5, mirrors config/fcitx5) -----------------------
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-gtk ];
  };

  # --- Sound ------------------------------------------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  system.stateVersion = "24.11";
}
