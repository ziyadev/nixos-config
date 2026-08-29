# nixos-config

Dotfiles/config exported from an [Omarchy](https://omarchy.org) machine
(Arch Linux + Hyprland + Omarchy's QML shell), for testing on a NixOS
laptop via home-manager.

This is a **starting point, not a finished NixOS setup**. Omarchy is a
whole opinionated Arch-based distro (its own installer, pacman hooks, a
custom QML desktop shell/bar, Lua-based Hyprland bootstrapping) — none of
that infrastructure exists on NixOS. What's vendored here is your actual
personal config/override files, copied as-is, so you have something
concrete to diff against and adapt rather than starting from a blank
`~/.config`.

## What's in here

```
config/            Raw copy of ~/.config/* from the Omarchy machine
  hypr/             Your Hyprland overrides (Lua) — see caveat below
  omarchy/          Omarchy shell config: branding, hooks, themes, plugins,
                     shell.json (bar layout/theme). Excludes tableau.toml
                     (hardcoded /usr/lib/chromium paths + a public Chromium
                     OAuth placeholder — not portable, not worth carrying).
  alacritty/ foot/ kitty/ ghostty/   Terminal emulator configs
  nvim/             Full Neovim config (LazyVim-based)
  tmux/ btop/ lazygit/ starship.toml mise/
  git/              gitconfig + git ignore (uses `gh auth git-credential`)
  fcitx5/           Input method config
  nwg-displays/ gtk-3.0/ autostart/ mimeapps.list

home-manager/
  home.nix          home-manager module that symlinks config/* into place
                     via xdg.configFile, plus a package list mirroring what
                     was installed on the Arch box

hosts/laptop/
  configuration.nix        Placeholder NixOS system config (Hyprland,
                            networking, fcitx5, pipewire, a `ziyadev` user)
  hardware-configuration.nix   PLACEHOLDER — regenerate per-machine, see below

flake.nix           Wires the above together
```

**Deliberately left out:** `~/.config/gh/hosts.yml` (contains a live GitHub
OAuth token), `~/.config/omarchy/tableau.toml` (machine-specific paths +
the aforementioned OAuth string), and app data / caches / profiles for
Chromium, Google Chrome, Obsidian, Bitwarden (large, and personal data, not
config).

The QML plugins under `config/omarchy/plugins/*` are third-party
(`io.github.maxart.simple-workspaces`, `m1kode.obsidian-tasks`,
`novuon.tableau`, `propsuite.dell-input`) — vendored here as plain files
(their nested `.git` dirs were stripped) purely for reference. They belong
to their own upstream repos/licenses.

## The big caveat: Hyprland config is Lua, and expects Omarchy

`config/hypr/hyprland.lua` does this:

```lua
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
...
require("default.hypr.omarchy")
```

That pulls in Omarchy's own defaults from `/usr/share/omarchy`, which only
exists on an Omarchy install. On NixOS this file will fail to load as-is.
Your actual personal overrides — the parts you'd care about porting — are:

- `hypr/monitors.lua` / `monitors.conf`
- `hypr/input.lua`
- `hypr/bindings.lua`
- `hypr/looknfeel.lua`
- `hypr/autostart.lua`

Two realistic paths forward, worth trying on the test laptop:

1. **Vendor Omarchy's Lua defaults too.** Omarchy is open source
   (github.com/basecamp/omarchy) — you could pull `default/hypr/*.lua` from
   its repo into this one and package `hyprland-lua` (whatever Hyprland
   config-lang plugin Omarchy relies on) as a Nix derivation. More
   faithful, more work.
2. **Rewrite as plain `hyprland.conf`.** Translate the handful of lines in
   the five files above into standard Hyprland config syntax and drop the
   `dofile`/`require` scaffolding entirely. Loses Omarchy's shared defaults
   but is the path of least resistance on NixOS, and `programs.hyprland` in
   `hosts/laptop/configuration.nix` expects this.

Either way, the *bar/shell* (`omarchy/shell.json` + the QML plugins) is
Omarchy-specific UI you'd need to replace with something NixOS-native
(waybar, ags/astal, quickshell, etc.) — the JSON/QML here is reference
material for recreating the same layout/behavior, not a drop-in.

## Trying it on the other laptop

```bash
git clone git@github.com:ziyadev/nixos-config.git
cd nixos-config

# 1. Get real hardware info for that machine (overwrites the placeholder):
sudo nixos-generate-config --dir ./hosts/laptop

# 2a. Just the dotfiles, on an existing NixOS install with home-manager:
home-manager switch --flake .#ziyadev

# 2b. Or a full system switch (edit hosts/laptop/configuration.nix first —
#     hostname, timezone, disks/bootloader assumptions):
sudo nixos-rebuild switch --flake .#laptop
```

Expect to iterate — this repo captures where you started from, not a
tested end state.
