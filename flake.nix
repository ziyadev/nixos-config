{
  description = "Personal dotfiles/config, ported from an Omarchy (Arch + Hyprland) machine, for testing on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      # Standalone home-manager configuration you can activate on any NixOS
      # box without wiring it into your system flake first:
      #   home-manager switch --flake .#ziyadev
      homeConfigurations.ziyadev = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home-manager/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      # Placeholder full-system config for the other laptop. Fill in
      # hardware-configuration.nix (generate with `nixos-generate-config`)
      # and adjust hosts/laptop/configuration.nix, then:
      #   sudo nixos-rebuild switch --flake .#laptop
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ziyadev = import ./home-manager/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
