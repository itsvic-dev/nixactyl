{ self, pkgs }:
pkgs.nixosTest {
  name = "nixactyl-starts";
  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.default ];

    services.nixactyl = {
      enable = true;
      artisanWrapper = true;

      srcs = (import ../versions.nix { inherit pkgs; })."1.11.11" // {
        prebuiltAssets = false;
        modulesHash = "sha256-Pv2/0kfOKaAMeioNU1MBdwVEMjDbk+QR8Qs1EwA5bsQ=";
      };

      nginx = {
        enable = true;
        virtualHost = "localhost";
      };
    };

    services.nginx.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("phpfpm-nixactyl.service")
    machine.succeed("curl -f localhost")
  '';
}
