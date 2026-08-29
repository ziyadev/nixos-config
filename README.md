# nixos-config

A full attempt at reproducing this laptop's [Omarchy](https://omarchy.org)
desktop (Arch Linux + Hyprland + Omarchy's Quickshell-based shell) on
NixOS, for testing on a second laptop.

**Status: written, not build-tested.** There is no `nix` binary on this
(Arch) machine to run `nix flake check` against, so treat this as a strong
first draft to `nixos-rebuild build` against on the real target and fix
forward — not a guarantee every package name and option below is exactly
right. Where I was genuinely unsure of a nixpkgs name, it's flagged inline
with a comment.

## What "everything" means here

Rather than a hand-picked subset, `vendor/omarchy` is a **verbatim clone of
upstream `basecamp/omarchy` at tag `v4.0.1`** — the exact version this
machine runs (`diff -rq` against the live `/usr/share/omarchy` comes back
clean). That's all 430 `omarchy-*` helper scripts, the full Quickshell
QML shell (bar, app menu, launcher, lock screen, notifications — the thing
that opens on `SUPER+SPACE`), every Hyprland Lua binding, all 22 built-in
themes, fonts, the sddm/plymouth boot theme, and the canonical package
list. See `vendor/VENDOR.md` for exactly how it was pulled and how to
refresh it later. Nothing was selectively copied or summarized — if it's
in upstream Omarchy 4.0.1, it's in this repo.

On top of that, `config/` still holds your personal `~/.config` overrides
from the previous pass (hypr bindings/monitors/input overrides, terminal
configs, nvim, tmux, git, starship, etc.) — see the bottom of this file for
what's excluded there and why (a live GitHub token, one machine-specific
file).

## Repo layout

```
vendor/omarchy/     Verbatim upstream Omarchy v4.0.1 source (see VENDOR.md)
config/             Your personal ~/.config overrides (previous pass)
modules/omarchy.nix NixOS module: wires vendor/omarchy into a real system
home-manager/home.nix   Symlinks config/* into place, user packages
hosts/laptop/       Placeholder host config — hostname, disks, bootloader
flake.nix           Wires it all together
```

## How `modules/omarchy.nix` actually reproduces Omarchy

- **`vendor/omarchy` → `/usr/share/omarchy`.** A handful of vendored
  scripts hardcode `/usr/share/omarchy` instead of going through
  `$OMARCHY_PATH` (e.g. the uwsm env.d file that sources
  `default/bash/env-bootstrap`). NixOS doesn't populate `/usr`, but `/` is
  a normal writable filesystem, so a `system.activationScripts` symlink
  recreates that path deliberately, rather than patching 430 scripts.
  `OMARCHY_PATH` is also set explicitly for everything that does the right
  thing and reads the env var.
- **Hyprland is built from `github:hyprwm/Hyprland` pinned to the exact
  commit this laptop reports** (`hyprctl version`), not nixpkgs' own
  hyprland package — because `hyprland.lua`'s `dofile()`/Lua config
  loading needs to match upstream's Lua support precisely.
- **Quickshell** comes from its own flake (`quickshell-mirror/quickshell`),
  which is what actually renders Omarchy's bar/menu/launcher —
  `default/hypr/autostart.lua` execs `omarchy-launch-shell`, which runs
  `quickshell -p $OMARCHY_PATH/shell`.
- **uwsm** launches Hyprland the same way Omarchy's own session file does
  (`uwsm start -g -1 -e -D Hyprland hyprland.desktop`), via NixOS's
  `programs.uwsm.waylandCompositors`.
- **sddm + plymouth** use Omarchy's actual theme assets, packaged from the
  vendored `default/sddm/omarchy` and `default/plymouth`.
- **The package list** is `install/omarchy-base.packages` (Omarchy's own
  canonical Arch package manifest — not something I compiled by hand)
  translated to nixpkgs names package-by-package. Deliberately **not**
  included:
  - `install/omarchy-other.packages` — hardware-specific drivers (Nvidia,
    Asus, Framework, T2 Mac, Surface, Broadcom Wi-Fi, various DKMS
    modules). Pick from there based on the *actual* hardware of the laptop
    you're testing on, after `nixos-generate-config` tells you what it has.
  - Arch-only tooling with no NixOS meaning: `pacman-contrib`, `expac`,
    `kernel-modules-hook`, `yay` (AUR helper), `limine`/`limine-snapper-sync`
    (NixOS's own generation rollback replaces the Btrfs-snapshot boot menu
    entirely — see the comment in `hosts/laptop/configuration.nix`).
  - Omarchy's own closed-source-to-nixpkgs custom tools with no package
    upstream: `aether`, `cliamp`, `herdr`, `omacalc`, `omacut`, `omawrite`,
    `tensaku`, `tobi-try`, `ttfx`, `usage`. If you rely on any of these
    day-to-day, they'd need to be packaged separately (many are on AUR —
    check if they're just source-available and buildable as a plain Nix
    derivation).
  - `omarchy-nvim` — not needed; your actual nvim config is already
    vendored verbatim in `config/nvim`.

## First boot on the test laptop

```bash
git clone git@github.com:ziyadev/nixos-config.git
cd nixos-config

sudo nixos-generate-config --dir ./hosts/laptop   # real hardware-configuration.nix
# edit hosts/laptop/configuration.nix: hostname, timezone, add any
# hardware-specific packages from vendor/omarchy/install/omarchy-other.packages

sudo nixos-rebuild build --flake .#laptop   # build without switching first — see what breaks
sudo nixos-rebuild switch --flake .#laptop
```

After first login, regenerate the active-theme state (the terminal configs
in `config/` all `include`/`import` `~/.local/state/omarchy/current/theme/*`
for colors — that directory is *generated*, not something to copy from the
old machine, since it also contains an absolute-path symlink):

```bash
omarchy-theme-set vantablack   # or: omarchy-theme-list, to see all 22
```

Expect to iterate from here — this is a from-scratch NixOS reproduction of
a fast-moving, Arch-native distro, not a tested end state. Report back
whatever breaks first (most likely candidates: a mistranslated package
name in `modules/omarchy.nix`, or a `bin/omarchy-*` script that shells out
to something Arch-specific like `pacman` or `systemctl` against a service
NixOS names differently) and it's straightforward to fix forward from
there.

## The `config/` overrides (previous pass, re-checked)

Your personal `~/.config` overrides, symlinked into place by
`home-manager/home.nix`. Re-verified by diffing every file here against
`vendor/omarchy/config` (Omarchy's own skeleton for a fresh install) —
that's how the six directories missed in the first pass got caught
(`herdr`, `hyprland-preview-share-picker`, `imv`, `opencode`, `wireplumber`,
`xournalpp`), and how two live bugs surfaced: `config/foot/foot.ini` and
`config/git/config` had `/usr/bin/zsh` and `/usr/bin/gh` hardcoded — real
paths on Arch, nonexistent on NixOS (no `/usr/bin` there beyond the `env`
compat shim) — now changed to bare command names so the shell and `gh`
credential helper resolve via `PATH` instead of silently failing.

**Deliberately excluded:** `~/.config/gh/hosts.yml` (a live GitHub OAuth
token) and `~/.config/omarchy/tableau.toml` (hardcoded `/usr/lib/chromium`
paths from this machine, not portable). Also excluded: Chromium/Google
Chrome/Obsidian/Bitwarden app data — personal data and caches, not config.

One more thing the diff surfaced worth knowing about, not fixing:
`hypr/monitors.lua`/`monitors.conf` were generated by `nwg-displays` for
*this* laptop's actual screen. Sanity-check them on the test laptop rather
than assuming the resolution/scale carries over.

The QML plugins under `config/omarchy/plugins/*` are third-party
(`io.github.maxart.simple-workspaces`, `m1kode.obsidian-tasks`,
`novuon.tableau`, `propsuite.dell-input`) — vendored as plain files (their
nested `.git` dirs stripped) for reference; they belong to their own
upstream repos/licenses.
