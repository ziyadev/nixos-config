{ config, pkgs, lib, ... }:

let
  dotfiles = ../config;
in
{
  home.username = "ziyadev";
  home.homeDirectory = "/home/ziyadev";
  home.stateVersion = "24.11";

  # Let home-manager manage itself.
  programs.home-manager.enable = true;

  # Packages that mirror the Omarchy/Arch install. Trim/extend as you
  # discover what NixOS actually needs vs. what pacman pulled in for you
  # automatically.
  home.packages = with pkgs; [
    alacritty
    foot
    kitty
    ghostty
    btop
    lazygit
    tmux
    starship
    fcitx5
    neovim
    mise
  ];

  programs.git = {
    enable = true;
    # Real config content is symlinked in below from config/git; this just
    # makes sure git itself is installed.
  };

  # ---------------------------------------------------------------------
  # Straight symlinks of the copied dotfiles. This is the fastest path to
  # "does my Omarchy setup even work on NixOS": point the real config paths
  # at the files vendored in ../config and iterate from there.
  #
  # NOTE: ~/.config/hypr here is Omarchy's own config, written expecting
  # Omarchy's Lua bootstrap (dofile $OMARCHY_PATH/default/hypr/bootstrap.lua)
  # and its `default.hypr.*` Lua modules to exist on disk. None of that
  # ships on NixOS, so hypr/hyprland.lua will NOT work as-is until you either
  # (a) vendor omarchy's own lua defaults alongside it, or (b) rewrite
  # bindings.lua / input.lua / looknfeel.lua / monitors.lua / autostart.lua
  # into a plain hyprland.conf. See README.md.
  # ---------------------------------------------------------------------
  xdg.configFile = {
    "hypr".source = "${dotfiles}/hypr";
    "alacritty".source = "${dotfiles}/alacritty";
    "foot".source = "${dotfiles}/foot";
    "kitty".source = "${dotfiles}/kitty";
    "ghostty".source = "${dotfiles}/ghostty";
    "nvim".source = "${dotfiles}/nvim";
    "tmux".source = "${dotfiles}/tmux";
    "btop".source = "${dotfiles}/btop";
    "mise".source = "${dotfiles}/mise";
    "lazygit".source = "${dotfiles}/lazygit";
    "git".source = "${dotfiles}/git";
    "nwg-displays".source = "${dotfiles}/nwg-displays";
    "gtk-3.0".source = "${dotfiles}/gtk-3.0";
    "fcitx5".source = "${dotfiles}/fcitx5";
    "autostart".source = "${dotfiles}/autostart";
    "omarchy".source = "${dotfiles}/omarchy";
    "starship.toml".source = "${dotfiles}/starship.toml";
    "mimeapps.list".source = "${dotfiles}/mimeapps.list";
  };
}
