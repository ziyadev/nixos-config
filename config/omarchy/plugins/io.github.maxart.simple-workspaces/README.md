# Simple Workspaces

![Simple Workspaces preview](preview.png)

A minimal workspace widget for the Omarchy Quattro bar. It replaces the stock
rounded squares and numbers with small circles:

- The active workspace is fully opaque.
- Occupied inactive workspaces are 20% opaque.
- Empty inactive workspaces are 10% opaque.

Like the native widget, it always shows workspaces 1–5 and adds existing
workspaces through 10. Click a circle to focus its workspace. Horizontal and
vertical bars are both supported.

## Requirements

- Omarchy Quattro
- No external dependencies or privileged setup

## Install

```sh
omarchy plugin add https://github.com/maxart/simple-workspaces.git --enable
omarchy plugin disable omarchy.workspaces
omarchy bar move io.github.maxart.simple-workspaces --section left
```

## Validate

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.maxart.simple-workspaces
qmllint -I "$OMARCHY_PATH/shell" \
  ~/.config/omarchy/plugins/io.github.maxart.simple-workspaces/Workspaces.qml
```

## Remove

```sh
omarchy plugin remove io.github.maxart.simple-workspaces --yes
omarchy plugin enable omarchy.workspaces left
```

## License

MIT. This plugin is derived from Omarchy's native Workspaces widget.
