{ srcs, stdenv, runCommand, patch, php83Packages, yarnConfigHook, yarnBuildHook
, fetchYarnDeps, nodejs }:
let
  builtPanel = if srcs.prebuiltAssets then
    srcs.src
  else
    stdenv.mkDerivation {
      name = "pterodactyl-with-assets";
      inherit (srcs) src version;

      yarnOfflineCache = fetchYarnDeps {
        yarnLock = srcs.src + "/yarn.lock";
        hash = srcs.modulesHash;
      };

      yarnBuildScript = "build:production";

      NODE_OPTIONS = "--openssl-legacy-provider";

      installPhase = ''
        mkdir -pv $out
        cp -r . $out
      '';

      nativeBuildInputs = [ yarnConfigHook yarnBuildHook nodejs ];
    };

  vendor = stdenv.mkDerivation {
    pname = "pterodactyl-vendor";
    inherit (srcs) src version;

    nativeBuildInputs = [ php83Packages.composer ];

    outputHash = srcs.vendorHash;
    outputHashMode = "nar";
    outputHashAlgo = "sha256";

    buildPhase = ''
      composer install --no-dev --optimize-autoloader
    '';

    installPhase = ''
      cp -r vendor $out
    '';

    dontFixup = true;
  };

in stdenv.mkDerivation {
  pname = "pterodactyl";
  inherit (srcs) version;
  src = builtPanel;

  patches =
    [ ../patches/bootstrap-paths.patch ../patches/file-sessions-env.patch ];

  installPhase = ''
    mkdir $out
    # right now, we need to copy everything over, otherwise autoloading breaks
    cp -r . $out/
    cp -r "${vendor}" $out/vendor
  '';

  dontFixup = true;
}

# nerdy details:

# when composer sets up autoload, it loads all files relative to __DIR__, aka this file's directory
# this means it also loads the \Pterodactyl namespace as relative to __DIR__/../../app

# in a normal setup, this works fine:
# panel/vendor/composer/../../app -> panel/app

# but in our case, if we symlink it...
# /nix/store/...-vendor/../../app -> /nix/app
# which is NOT where we want to load.

# similarly, when index.php tries to bootstrap the autoloader,
# it will resolve the symlink, then try to load ...-source/../vendor/autoload.php
# which doesn't exist in the source.

# i'm not sure if this is something we could solve,
# unless we patch the generated autoload files.
