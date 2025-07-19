{ config, pkgs, ... }: {
  services.getty.autologinUser = "test";
  users.users.test = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "test";
  };
  security.sudo.wheelNeedsPassword = false;

  services.nixactyl = {
    enable = true;
    artisanWrapper = true;
    statefulDir = "/var/ptero-data";

    nginx = {
      enable = true;
      virtualHost = "localhost";
    };
  };

  services.nginx.enable = true;

  # services.xserver.enable = true;
  # services.xserver.desktopManager.xfce.enable = true;
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.displayManager.lightdm.greeters.gtk.enable = true;

  environment.systemPackages = [ pkgs.chromium ];

  system.stateVersion = "24.05";
}
