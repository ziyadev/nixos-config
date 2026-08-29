# Omarchy marketplace publishing checklist

## Before submission

- [x] Root `manifest.json` uses schema version 1 and a permanent plugin ID.
- [x] README documents requirements, installation, use, configuration, and removal.
- [x] MIT license is included.
- [x] Hotkeys are disabled by default and Hyprland changes require explicit opt-in.
- [x] Runtime state is kept outside the Git checkout.
- [x] README uses the final GitHub username, `HazIQ-DevOps`.
- [x] Push this directory to a public GitHub repository.
- [x] Added `preview.png` showing the corrected popup layout.
- [x] Final validation and clean-install checks pass from a fresh public checkout.

## Marketplace form draft

**Title:** `[Plugin]: DDC Input Switcher`

**Repository URL:** `https://github.com/HazIQ-DevOps/omarchy-ddc-input-switcher`

**Category:** Hardware

**Tags:** Bar, Quickshell, System

**Suggested missing tag:** DDC/CI

**Maintainer notes:**

Requires `ddcutil`, a DDC/CI-enabled display, and read/write access to the
relevant `/dev/i2c-*` device. The helper does not use `sudo` or `pkexec`. It
reads and writes only VCP feature `0x60`, with supported source values `0x0f`,
`0x11`, and `0x12`. Hotkeys are disabled by default. Selecting a preset is an
explicit opt-in that creates only the plugin-owned
`~/.config/hypr/propsuite-dell-input.lua`; the user must separately add its
loader line to `bindings.lua`. Runtime state is stored under
`$XDG_STATE_HOME/omarchy/plugins/propsuite.dell-input`.

## Submission checklist

- [x] The repository is public and contains install/removal instructions.
- [x] The license and dependencies are documented.
- [x] Permission to publish under the PropSuite author name is confirmed. No
      PropSuite logo or other PropSuite visual asset is bundled; `preview.png`
      is the user-provided plugin screenshot.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] Marketplace approval is understood not to be a security review.
