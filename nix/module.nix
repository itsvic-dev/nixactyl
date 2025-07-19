{ pkgs, lib, config, ... }:
let
  versions = import ./versions.nix { inherit pkgs; };
  cfg = config.services.nixactyl;

  panel = pkgs.callPackage ./buildPanel.nix { inherit (cfg) srcs; };

  nixactylEnv = {
    "LARAVEL_STORAGE_PATH" = "${cfg.statefulDir}/storage";
    "NIXACTYL_BOOTSTRAP_PATH" = "${cfg.statefulDir}/bootstrap";
    "NIXACTYL_ENV_PATH" = cfg.envFile;
    "VIEW_COMPILED_PATH" = "${cfg.statefulDir}/storage/framework/views";
  };
in {
  options = {
    services.nixactyl = {
      enable = lib.mkEnableOption "Nixactyl";
      artisanWrapper = lib.mkEnableOption "nixactyl-artisan wrapper program";

      version = lib.mkOption {
        type = lib.types.enum (builtins.attrNames versions);
        default = "latest";
        example = "1.11.11";
      };

      srcs = lib.mkOption {
        type = lib.types.attrs; # TODO: be more strict about this
        default = versions."${cfg.version}";
      };

      php = lib.mkOption {
        type = lib.types.package;
        default = pkgs.php;
      };

      statefulDir = lib.mkOption {
        type = lib.types.str;
        example = "/var/ptero-data";
      };

      envFile = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.statefulDir}/.env";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = config.services.nginx.user;
      };

      nginx = {
        enable = lib.mkEnableOption "Nginx configuration for Nixactyl";
        virtualHost = lib.mkOption {
          type = lib.types.str;
          example = "my-panel.example.com";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.pools.nixactyl = {
      user = cfg.user;
      phpPackage = cfg.php;
      settings = {
        "listen.owner" = cfg.user;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
      phpEnv = nixactylEnv // { "PATH" = lib.makeBinPath [ pkgs.php ]; };
    };

    systemd.tmpfiles.settings."10-nixactyl" = lib.genAttrs [
      cfg.statefulDir
      "${cfg.statefulDir}/storage"
      "${cfg.statefulDir}/storage/logs"
      "${cfg.statefulDir}/storage/framework"
      "${cfg.statefulDir}/storage/framework/cache"
      "${cfg.statefulDir}/storage/framework/views"
      "${cfg.statefulDir}/storage/framework/sessions"
      "${cfg.statefulDir}/bootstrap"
      "${cfg.statefulDir}/bootstrap/cache"
    ] (_name: {
      d = {
        mode = "0750";
        user = cfg.user;
        group = "nogroup";
      };
    });

    systemd.services."nixactyl-ensure-env-exists" = {
      wantedBy = [ "phpfpm-nixactyl.service" ];
      before = [ "phpfpm-nixactyl.service" ];
      after = [ "systemd-tmpfiles-resetup.service" ];
      description = "Ensure that Nixactyl .env file exists";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
      };
      environment = nixactylEnv;
      script = ''
        set -e
        if [ ! -f "${cfg.envFile}" ]; then
          echo ".env file does not exist, copying example one and generating key"
          cp "${panel}/.env.example" "${cfg.envFile}"
          chmod 600 "${cfg.envFile}"
          ${lib.getExe pkgs.php} "${panel}/artisan" key:generate
        fi
      '';
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      virtualHosts.${cfg.nginx.virtualHost} = {
        root = "${panel}/public";
        extraConfig = ''
          index = index.php;
          client_max_body_size 100m;
          client_body_timeout 120s;
        '';

        locations."/" = {
          extraConfig = ''
            try_files $uri $uri/ /index.php?$query_string;
          '';
        };

        locations."~ \\.php$" = {
          extraConfig = ''
            fastcgi_pass unix:${config.services.phpfpm.pools.nixactyl.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${config.services.nginx.package}/conf/fastcgi_params;
            fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param HTTP_PROXY "";
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 300;
          '';
        };
      };
    };

    environment = lib.mkIf cfg.artisanWrapper {
      systemPackages = [
        (pkgs.writeShellApplication {
          name = "nixactyl-artisan";
          runtimeInputs = [ cfg.php ];
          runtimeEnv = nixactylEnv;
          text = ''exec php ${panel}/artisan "$@"'';
        })
      ];
    };
  };
}
