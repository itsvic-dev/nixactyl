{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      nixosModules = rec {
        nixactyl = import ./nix/module.nix;
        default = nixactyl;
      };

      # run only Linux checks on Hydra. we don't have Darwin runners internally
      hydraJobs = { inherit (self.checks) x86_64-linux aarch64-linux; };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        checks = {
          starts = pkgs.callPackage ./nix/tests/starts.nix { inherit self; };
        };
      });
}
