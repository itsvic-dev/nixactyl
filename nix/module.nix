{ pkgs, lib, config }:
let
  versions = import ./versions.nix { inherit pkgs; };
  cfg = config.services.nixactyl;

  panel =
    pkgs.callPackage ./buildPanel.nix { srcs = versions."${cfg.version}"; };
in {
  options = {
    services.nixactyl = {
      enable = lib.mkEnableOption "Nixactyl";
      version = lib.mkOption {
        type = lib.types.enum (builtins.mapAttrs (name: f: name) versions);
        default = "latest";
        example = "1.11.11";
      };
      statefulDir = lib.mkOption {
        type = lib.types.str;
        example = "/var/ptero-data";
      };
    };
  };

  config = {

  };
}
