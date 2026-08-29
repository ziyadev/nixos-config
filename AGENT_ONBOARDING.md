# Prompt: deploying this repo on the NixOS test laptop

Paste this whole file to the agent running on the NixOS laptop before it
touches anything.

---

You're deploying `github.com/ziyadev/nixos-config` (private repo) on this
NixOS machine. Read `README.md` and `vendor/VENDOR.md` in the repo fully
before doing anything else.

**What this repo is**: a from-scratch reproduction of an Omarchy
(Arch+Hyprland) desktop on NixOS. It vendors upstream Omarchy v4.0.1
verbatim (`vendor/omarchy/`) plus one person's `~/.config` overrides
(`config/`), wired together by a NixOS module (`modules/omarchy.nix`),
a home-manager module (`home-manager/home.nix`), and `flake.nix`.
**`hosts/laptop/` is a placeholder** — its hostname, timezone, bootloader
assumption, and (empty) hardware-configuration.nix are generic guesses,
not this machine's real values.

**This machine already runs NixOS with its own working configuration.**
That existing configuration — whatever is at `/etc/nixos/` or wherever its
flake lives — is the *source of truth* for anything hardware, disk, or
bootloader related. This repo's placeholder never overrides it; it gets
filled in *from* it.

## Hard rules — non-negotiable, not judgment calls

1. **Never touch partitions, filesystems, LUKS, or disk layout.** No
   `disko`, `mkfs`, `parted`, `fdisk`, `wipefs`, `cfdisk`, or anything that
   writes to a block device. Nothing here should ever require it — if a
   step seems to need it, stop and ask, don't improvise.
2. **Never hand-write or copy in `hardware-configuration.nix`.** Always
   generate this machine's real one:
   `sudo nixos-generate-config --dir <path-to-repo>/hosts/laptop`
   That command reads *this* machine's actual disks/filesystems/kernel
   modules and writes the file — it's the only legitimate source for it.
   Read the output before trusting it.
3. **Back up the current config before changing anything**:
   `sudo cp -r /etc/nixos /etc/nixos.bak-$(date +%Y%m%d-%H%M%S)`
   (adjust the path if this machine is already flake-managed from
   somewhere else — back up wherever its real config actually lives).
4. **Build before you switch, every time.**
   `sudo nixos-rebuild build --flake <path>#laptop` first — this compiles
   without touching the running system at all. Only run
   `sudo nixos-rebuild switch --flake <path>#laptop` once `build` succeeds
   cleanly. Never go straight to `switch`, and never use `boot` +
   unattended reboot as a substitute for actually looking at build errors.
5. **Match the existing bootloader, don't guess.** Check what this machine
   currently uses (`systemd-boot` vs `GRUB` vs anything else) before
   touching `boot.loader.*` in `hosts/laptop/configuration.nix` — the repo
   defaults to `systemd-boot`/EFI, which is wrong if this machine boots
   BIOS/GRUB. Getting this wrong can leave the machine unbootable.
6. **Know the rollback path before switching, not after.** NixOS keeps old
   generations bootable from the boot menu, and
   `sudo nixos-rebuild switch --rollback` reverts instantly — but only if
   you can reach a TTY or the boot menu. Confirm you know how to get to a
   text console (e.g. `Ctrl+Alt+F3`) on this hardware *before* the first
   switch, in case the graphical session (sddm/Hyprland/Quickshell) fails
   to come up.
7. **Don't guess this machine's hardware.** `vendor/omarchy/install/omarchy-other.packages`
   lists Nvidia/Asus/Framework/T2-Mac/Surface/Broadcom-specific drivers —
   run `lspci` / `inxi -Fxxxz` (or read the machine's own existing
   hardware-configuration.nix) and add only what actually matches. Adding
   driver packages for hardware this laptop doesn't have is at best inert,
   at worst can break boot (e.g. forcing an Nvidia DKMS module on
   non-Nvidia hardware).
8. **Don't discard what's already configured on this machine.** Before
   swapping in `hosts/laptop/configuration.nix` wholesale, diff it against
   the machine's real current config for things the repo doesn't know
   about — VPN, printers, a work-specific service, disk encryption unlock,
   swap/zram setup, existing users — and carry those forward deliberately.
9. **When genuinely unsure, stop and ask** rather than picking the
   option that seems least likely to break something. A wrong guess on
   any of the above can mean an unbootable machine; a paused task costs
   nothing.

## Procedure

1. Report current state first: is this machine flake-managed already, or
   classic `/etc/nixos/configuration.nix` + `hardware-configuration.nix`?
   Show a summary before doing anything else.
2. Back up the current config (rule 3).
3. Clone the repo, read `README.md` + `vendor/VENDOR.md` fully.
4. Generate this machine's real `hosts/laptop/hardware-configuration.nix`
   (rule 2). Sanity-check the filesystem/UUID entries against `lsblk`/`blkid`.
5. Reconcile `hosts/laptop/configuration.nix`: hostname, timezone,
   bootloader (rule 5), and anything from the machine's existing config
   that isn't represented in this repo yet (rule 8).
6. Identify real hardware and add only the matching entries from
   `omarchy-other.packages` (rule 7).
7. `nixos-rebuild build` — iterate here until it's clean (rule 4). Most
   likely failures: a mistranslated nixpkgs package name in
   `modules/omarchy.nix`, or a version mismatch between the pinned
   `hyprland`/`quickshell` flake inputs and what `nixpkgs` provides.
8. `nixos-rebuild switch`, only once step 7 is clean.
9. Reboot deliberately rather than trusting a live switch for anything
   touching the display manager, and be ready to pick the previous
   generation from the boot menu if the session doesn't come up.
10. After a successful login: `omarchy-theme-set <theme-name>` (see
    `omarchy-theme-list`) to materialize the themed per-app configs —
    `~/.local/state/omarchy/current/theme/*` is generated, not something
    carried over from the old machine.
11. Report back whatever breaks, in the order it breaks, rather than
    silently working around failures or skipping steps.
