# vendor/omarchy

Verbatim upstream source, not a hand-copy: `git clone --depth 1 --branch v4.0.1
https://github.com/basecamp/omarchy.git`, with `.git/` stripped afterwards.

- **Source**: https://github.com/basecamp/omarchy
- **Tag**: `v4.0.1` (commit `13f18b2cb7286fb54f87daf571a031aa6af3d8f0`)
- **License**: MIT, Copyright David Heinemeier Hansson — see `omarchy/LICENSE`
- **Vendored**: 2026-08-29
- **Verified identical** to this machine's live install: `diff -rq` against
  `/usr/share/omarchy` came back clean for every directory checked
  (`default/hypr`, `shell`), and `pacman -Qi omarchy` reports the same
  `4.0.1-1`. This is not a reconstruction — it's the exact tree this laptop
  is running.

This is the *entire* upstream repo: `bin/` (430 `omarchy-*` helper scripts),
`default/` (Hyprland Lua config, shell env, fonts, plymouth/sddm themes,
per-app config for every terminal/editor Omarchy themes), `shell/` (the
Quickshell QML bar/menu/launcher/lock screen), `themes/` (22 built-in
color schemes with wallpapers), `install/` (the Arch installer + the
canonical package manifest), `migrations/`, `applications/`, `config/`,
`etc/`, `agents/`, `manual/`, `docs/`, `test/`.

To refresh this against a newer Omarchy release:

```bash
rm -rf vendor/omarchy
git clone --depth 1 --branch vX.Y.Z https://github.com/basecamp/omarchy.git vendor/omarchy
rm -rf vendor/omarchy/.git
```

then re-check `README.md` and `modules/omarchy.nix` for anything the new
release renamed or restructured (bindings, package list, shell layout).
