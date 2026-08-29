# Changelog

## 3.1.0 — 2026-08-27

- Prepared the plugin for the Omarchy marketplace publishing checklist.
- Made global hotkeys disabled by default and strictly opt-in.
- Prevented a fresh disabled configuration from writing Hyprland files.
- Added complete configuration and removal instructions.
- Added the missing DisplayPort label to switch notifications.

## 3.0.2 — 2026-08-27

- Fixed the popup content column collapsing to the Flickable's implicit width.
- Bound controls to `ScrollView.availableWidth`, matching Omarchy's native
  panel layout pattern.
- Widened and compacted the panel for readable labels and full-size controls.

## 3.0.1 — 2026-08-27

- Fixed stale helper paths after the generic helper rename.
- Added direct widget IPC for reliable popup testing and control.
- Serialized DDC operations to prevent status polling and discovery from
  contending for the same I²C device.

## 3.0.0 — 2026-08-27

- Added a native visual popup panel.
- Added monitor discovery and selection.
- Added visual Source A and Source B dropdowns.
- Added visual hotkey selection.
- Added a large source toggle control and live current-input state.
- Removed machine-specific monitor serial and home-directory assumptions.
- Added publication documentation, safety notes, and MIT licensing.
