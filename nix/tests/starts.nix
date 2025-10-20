{ self, pkgs }:
pkgs.nixosTest {
  name = "nixactyl-starts";
  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.default ];

    services.nixactyl = {
      enable = true;
      artisanWrapper = true;
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
