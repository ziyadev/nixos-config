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
6. **Set up and verify the backoff plan below *before* the first
   `switch` — not "know it exists," actually walk through it once while
   the machine is still in its known-good state.**
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

## Backoff plan — walk through this once before the first switch

NixOS's real safety net is generations: every `switch` adds one, the
previous ones stay bootable, and none of this repo's changes are
destructive to them *as long as you can still reach either a shell or the
boot menu*. The plan below exists to guarantee that "as long as" always
holds.

**Before touching anything, confirm all four:**

1. **A second way in that doesn't depend on this machine's display
   working.** If it has SSH enabled and you're not sitting at the
   keyboard, open (and keep open, in another terminal/device) an SSH
   session to it right now. If you're on the physical keyboard, confirm
   you can reach a TTY (`Ctrl+Alt+F3`/`F4`, back with `Ctrl+Alt+F1` or
   `F7`) and log in there. Do this *now*, while everything still works —
   don't assume it'll be there to try for the first time after a broken
   switch.
2. **The boot menu is actually reachable and shows generations.** Reboot
   once before making changes and confirm the systemd-boot/GRUB menu
   appears (note the keypress/timeout to catch it) and lists the current
   generation. This is the fallback that survives even a switch that
   makes the system fail to boot at all, not just fail to log in.
3. **A VM dry run before touching real hardware, if at all possible.**
   `sudo nixos-rebuild build-vm --flake <path>#laptop` builds a disposable
   QEMU VM of the new configuration — `./result/bin/run-*-vm` boots it
   without touching this machine at all. This won't catch hardware-driver
   issues (Nvidia/Wi-Fi/etc. don't exist in the VM), but it will catch a
   broken Hyprland/Quickshell/sddm session, a bad package reference, or a
   boot-order problem for free, with zero risk. Do this before the first
   real `switch`, not instead of the steps below.
4. **Don't garbage-collect until the new config is proven stable.**
   Specifically avoid `nix-collect-garbage -d` (or anything that prunes
   old generations/profiles) for at least a few days after switching —
   that's what deletes the rollback target. `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`
   should keep showing the pre-switch generation until you're confident.

**If something goes wrong, in order of severity:**

- **Booted, but the graphical session (sddm/Hyprland/Quickshell) is
  broken**: TTY or SSH in (step 1), then
  `sudo nixos-rebuild switch --rollback` — reverts to the previous
  generation immediately, no reboot needed for the system config (a
  reboot is still the clean way to get the display manager itself back to
  a known state).
- **Won't boot at all, or hangs before you can log in**: reboot, catch the
  boot menu (step 2), and manually select the previous generation entry.
  That boots the old, known-good system unconditionally — it does not
  depend on anything in this repo working. From there, either leave it
  (the failed generation just sits unused) or investigate before trying
  `switch` again.
- **A specific older generation, not just "one back"**: list them with
  `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`,
  then either boot that entry from the boot menu, or from a running
  system: `sudo /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch`.
- **Truly stuck with no shell and no boot menu reachable**: this means
  step 1 or step 2 above wasn't actually verified beforehand — which is
  the scenario this whole plan exists to prevent. Boot a NixOS live
  USB/ISO as a last resort to inspect/repair `/boot` and
  `/nix/var/nix/profiles/system`.

## Procedure

1. Report current state first: is this machine flake-managed already, or
   classic `/etc/nixos/configuration.nix` + `hardware-configuration.nix`?
   Show a summary before doing anything else.
2. Back up the current config (rule 3).
3. Clone the repo, read `README.md` + `vendor/VENDOR.md` fully.
4. Verify the backoff plan above — all four checks, actually done, not
   assumed.
5. Generate this machine's real `hosts/laptop/hardware-configuration.nix`
   (rule 2). Sanity-check the filesystem/UUID entries against `lsblk`/`blkid`.
6. Reconcile `hosts/laptop/configuration.nix`: hostname, timezone,
   bootloader (rule 5), and anything from the machine's existing config
   that isn't represented in this repo yet (rule 8).
7. Identify real hardware and add only the matching entries from
   `omarchy-other.packages` (rule 7).
8. `nixos-rebuild build` — iterate here until it's clean (rule 4). Most
   likely failures: a mistranslated nixpkgs package name in
   `modules/omarchy.nix`, or a version mismatch between the pinned
   `hyprland`/`quickshell` flake inputs and what `nixpkgs` provides.
9. Optional but recommended: `nixos-rebuild build-vm` and boot it
   (backoff-plan step 3) before touching real hardware.
10. `nixos-rebuild switch`, only once step 8 (and ideally step 9) is clean.
11. Reboot deliberately rather than trusting a live switch for anything
    touching the display manager, and be ready to use the backoff plan
    (previous boot-menu generation) if the session doesn't come up.
12. After a successful login: `omarchy-theme-set <theme-name>` (see
    `omarchy-theme-list`) to materialize the themed per-app configs —
    `~/.local/state/omarchy/current/theme/*` is generated, not something
    carried over from the old machine.
13. Report back whatever breaks, in the order it breaks, rather than
    silently working around failures or skipping steps.
