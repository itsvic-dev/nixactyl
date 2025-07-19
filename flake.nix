{
  description = "A very basic flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }: {
    nixosModules.default = import ./nix/module.nix;

    packages.aarch64-darwin.darwinVM =
      self.nixosConfigurations.test.config.system.build.vm;

    nixosConfigurations.test = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./nixos-test.nix
        self.nixosModules.default
        {
          virtualisation.vmVariant = {
            virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          };
        }
      ];
    };
  };
}
