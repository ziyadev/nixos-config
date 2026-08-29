{ config, lib, pkgs, inputs, ... }:

let
  system = pkgs.system;

  # The verbatim upstream tree, as a Nix store path.
  omarchySrc = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-source";
    version = "4.0.1";
    src = ../vendor/omarchy;
    dontBuild = true;
    installPhase = "cp -r . $out";
  };

  # Every omarchy-* helper script (bin/) is invoked by bare name from other
  # scripts, from Lua bindings, and from the Quickshell UI. Exposing them as
  # a package puts them on PATH via environment.systemPackages, the normal
  # NixOS way, without touching /usr.
  omarchyBin = pkgs.runCommand "omarchy-bin" { } ''
    mkdir -p "$out/bin"
    for f in ${omarchySrc}/bin/*; do
      ln -s "$f" "$out/bin/$(basename "$f")"
    done
  '';

  # Built from Omarchy's actual flake input so hyprland.lua's `dofile`/Lua
  # config support matches upstream exactly rather than whatever nixpkgs'
  # own hyprland derivation happens to build with.
  hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
  quickshellPkg = inputs.quickshell.packages.${system}.default;

  omarchyFonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-fonts";
    version = "4.0.1";
    src = "${omarchySrc}/default/fonts/omarchy";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp *.ttf $out/share/fonts/truetype/
    '';
  };

  plymouthTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-plymouth-theme";
    version = "4.0.1";
    src = "${omarchySrc}/default/plymouth";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/plymouth/themes/omarchy
      cp -r . $out/share/plymouth/themes/omarchy/
    '';
  };

  sddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-sddm-theme";
    version = "4.0.1";
    src = "${omarchySrc}/default/sddm/omarchy";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/omarchy
      cp -r . $out/share/sddm/themes/omarchy/
    '';
  };
in
{
  # ---------------------------------------------------------------------
  # /usr/share/omarchy — deliberately impure.
  #
  # Several vendored scripts hardcode this path rather than going through
  # $OMARCHY_PATH (e.g. default/uwsm/env.d/10-omarchy sources
  # /usr/share/omarchy/default/bash/env-bootstrap directly). Real Omarchy
  # is Arch, where that path is simply where the package manager put it.
  # NixOS doesn't populate /usr, but the root filesystem is writable, so a
  # plain symlink recreates the same on-disk contract every hardcoded path
  # assumes, instead of patching 430 scripts by hand.
  # ---------------------------------------------------------------------
  system.activationScripts.omarchyUsrShare = lib.stringAfter [ "usrbinenv" ] ''
    mkdir -p /usr/share
    ln -sfn ${omarchySrc} /usr/share/omarchy
  '';

  environment.variables.OMARCHY_PATH = "/usr/share/omarchy";

  # ---------------------------------------------------------------------
  # Hyprland, via uwsm, exactly as Omarchy's wayland-sessions/omarchy.desktop
  # launches it: `uwsm start -g -1 -e -D Hyprland hyprland.desktop`.
  # ---------------------------------------------------------------------
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      prettyName = "Omarchy (Hyprland uwsm)";
      comment = "Omarchy Hyprland session managed by uwsm";
      binPath = "${hyprlandPkg}/bin/Hyprland";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  # ---------------------------------------------------------------------
  # Display manager: sddm with Omarchy's own theme.
  # ---------------------------------------------------------------------
  services.displayManager.sddm = {
    enable = true;
    theme = "omarchy";
    package = pkgs.kdePackages.sddm;
    extraPackages = [ pkgs.kdePackages.qtsvg pkgs.kdePackages.qtvirtualkeyboard ];
  };
  # sddmTheme's $out/share/sddm/themes/omarchy reaches
  # /run/current-system/sw/share/... (sddm's ThemeDir) by being an
  # ordinary systemPackages entry, same as any other themes/icons package.

  boot.plymouth = {
    enable = true;
    themePackages = [ plymouthTheme ];
    theme = "omarchy";
  };

  # ---------------------------------------------------------------------
  # Fonts
  # ---------------------------------------------------------------------
  fonts.packages = with pkgs; [
    omarchyFonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
    # ttf-ia-writer has no obvious 1:1 nixpkgs package as of writing —
    # check search.nixos.org before relying on it.
  ];

  # ---------------------------------------------------------------------
  # Input method, audio, misc services matching Omarchy's defaults.
  # ---------------------------------------------------------------------
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # fcitx5-qt lives under qt6Packages, not as a top-level package.
    fcitx5.addons = with pkgs; [ fcitx5-gtk qt6Packages.fcitx5-qt ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.printing = {
    enable = true;
    cups-pdf.enable = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.power-profiles-daemon.enable = true;
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  virtualisation.docker.enable = true;

  # ---------------------------------------------------------------------
  # Package set, translated from vendor/omarchy/install/omarchy-base.packages
  # (the canonical Arch list Omarchy's own installer pacstraps). See
  # README.md's package-mapping notes for what was dropped and why:
  # AUR-only Omarchy tools with no nixpkgs equivalent, hardware-specific
  # drivers (omarchy-other.packages — pick per real hardware), and Arch
  # package-manager/bootloader/snapshot tooling that has no NixOS analogue
  # (pacman-contrib, expac, kernel-modules-hook, yay, limine, snapper —
  # NixOS's own generations replace the Btrfs-snapshot workflow entirely).
  # ---------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    omarchyBin
    quickshellPkg
    sddmTheme

    # CLI / shell utilities
    alsa-utils
    avahi
    bash-completion
    bat
    bluez
    bluez-tools
    brightnessctl
    btop
    clang
    ddcutil
    docker-buildx
    docker-compose
    dosfstools
    dua
    exfatprogs
    eza
    fakeroot
    fastfetch
    fd
    ffmpegthumbnailer
    fzf
    inetutils
    inotify-tools
    inxi
    jq
    lazydocker
    lazygit
    less
    libsecret
    libyaml
    llvm
    lua5_1
    luarocks
    man-db
    plocate
    python3Packages.pygobject3
    python3Packages.poetry-core
    qrencode
    ripgrep
    ruby
    slurp
    socat
    starship
    tesseract
    tldr
    tree-sitter
    tmux
    tzupdate
    udiskie
    unzip
    whois
    wireless-regdb
    wl-clipboard
    wtype
    yt-dlp
    zbar
    zoxide

    # GUI apps
    chromium
    evince
    gnome-disk-utility
    imagemagick
    imv
    kdenlive
    libreoffice-fresh
    localsend
    moonlight-qt
    # mpv itself, and mpv-mpris (an mpv *script*, not a standalone binary),
    # are wired per-user via home-manager's `programs.mpv` in home.nix —
    # dropping the script package here wouldn't make mpv load it.
    nautilus
    nautilus-python
    obs-studio
    obsidian
    pinta
    system-config-printer
    sushi
    xournalpp

    # Wayland / Hyprland ecosystem
    grim
    gpu-screen-recorder
    gum
    hyprpicker
    hyprsunset
    hyprland-qtutils # closest match to Arch's hyprland-guiutils — verify
    pamixer
    qt6.qtimageformats
    wireplumber
    xdg-terminal-exec

    # Theming
    gnome-themes-extra
    yaru-theme

    # dev
    dotnetCorePackages.runtime_8_0
    vips
  ];
}
