# DDC Input Switcher for Omarchy

A native Omarchy Shell bar plugin for visually switching monitor inputs with
DDC/CI. Click the bar widget to open a themed popup with a large A/B switch,
monitor selection, source dropdowns, and persistent hotkey settings.

## Features

- Native Omarchy `Panel`, `Dropdown`, and `Toggle` controls
- Live current-input display in the bar and popup
- Visual Source A / Source B configuration
- DisplayPort, HDMI-1, and HDMI-2 support
- Automatic or explicit `ddcutil` display selection
- Configurable global hotkey presets
- Automatic source-pair swapping when both dropdowns would match
- VCP writes restricted to input-source feature `0x60`
- Theme-aware and compatible with horizontal or vertical bars

## Requirements

- Omarchy with the Quickshell-based `omarchy-shell`
- `ddcutil`
- A monitor with DDC/CI enabled in its on-screen settings
- User access to the relevant `/dev/i2c-*` device

Install the dependency through Omarchy if necessary:

```sh
omarchy pkg add ddcutil
```

## Install

```sh
omarchy plugin add https://github.com/HazIQ-DevOps/omarchy-ddc-input-switcher.git --enable
```

The plugin is placed in the right bar section by default.

### Enable a persistent hotkey (optional)

Hotkeys are **disabled by default**. Selecting a preset in the popup is the
explicit opt-in that allows the plugin to create its own Hyprland binding
module.

Omarchy loads user bindings from `~/.config/hypr/bindings.lua`. Add this once:

```lua
require("hypr.propsuite-dell-input")
```

The plugin owns only `~/.config/hypr/propsuite-dell-input.lua`; changing the
hotkey in the popup regenerates that small file and reloads Hyprland. It never
rewrites `bindings.lua` or unrelated bindings. If you leave the setting on
**Disabled**, a fresh installation does not create a Hyprland file.

Then reload and validate:

```sh
hyprctl reload
hyprctl configerrors
```

## Use

1. Click the monitor-input widget in the Omarchy bar.
2. Pick a monitor or leave it on **Auto detect**.
3. Choose Source A and Source B.
4. Choose a hotkey preset or disable the hotkey.
5. Click the large toggle row to switch.

Settings are stored inline in `~/.config/omarchy/shell.json` and apply
immediately. The small helper cache lives under `$XDG_STATE_HOME` (normally
`~/.local/state`) so the plugin's Git checkout stays clean and updateable.

## Remove

1. Set the popup's hotkey to **Disabled**.
2. Remove `require("hypr.propsuite-dell-input")` from
   `~/.config/hypr/bindings.lua` if you added it.
3. Remove the plugin:

```sh
omarchy plugin remove propsuite.dell-input
```

The plugin deliberately leaves user configuration and state available for a
future reinstall. To clean up those plugin-owned files too, move them to the
desktop trash and reload Hyprland:

```sh
gio trash ~/.config/hypr/propsuite-dell-input.lua
gio trash ~/.local/state/omarchy/plugins/propsuite.dell-input
hyprctl reload
hyprctl configerrors
```

## Troubleshooting

Discover displays and read the current source:

```sh
~/.config/omarchy/plugins/propsuite.dell-input/ddc-input displays
~/.config/omarchy/plugins/propsuite.dell-input/ddc-input get
```

If no display appears, enable DDC/CI in the monitor menu and verify `ddcutil
detect --brief` works as your normal user.

## Security model

Omarchy plugins run as trusted user code. This plugin invokes `ddcutil` only
for display discovery, reading VCP `0x60`, and setting VCP `0x60` to one of the
three supported input values (`0x0f`, `0x11`, `0x12`). Monitor numbers, source
names, and hotkey values are validated before use.

## License

MIT
