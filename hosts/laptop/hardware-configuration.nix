# Placeholder. On the target laptop, run:
#
#   sudo nixos-generate-config --dir /path/to/this/repo/hosts/laptop
#
# That overwrites this file with the real hardware scan (filesystems,
# kernel modules, CPU microcode, etc.) for that specific machine. Do not
# hand-write this one — always regenerate it per-machine.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  # This file is intentionally incomplete until regenerated on-device.
}
