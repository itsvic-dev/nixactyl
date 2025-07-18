{ config, pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.getty.autologinUser = "test";
  users.users.test = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "test";
  };
  security.sudo.wheelNeedsPassword = false;

  services.nixactyl = {
    enable = true;
    statefulDir = "/var/ptero-data";

    nginx = {
      enable = true;
      virtualHost = "localhost";
    };
  };

  services.nginx = { enable = true; };

  system.stateVersion = "24.05";
}
