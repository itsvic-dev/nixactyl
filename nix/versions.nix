{ pkgs }:
let
  versions = {
    "1.11.11" = {
      version = "1.11.11";
      src = pkgs.fetchzip {
        url =
          "https://github.com/pterodactyl/panel/releases/download/v1.11.11/panel.tar.gz";
        hash = "sha256-0nOHtReVUVXYQY/glS4x0gkbhetoXSWg4rRwOJlkcM8=";
        stripRoot = false;
      };
      vendorHash = "sha256-jAQPL9V3scXWnf7ulgJ56obuQN+4sSsKDsX4e6nJ5CQ=";
      prebuiltAssets = true;
    };
  };
in versions // { latest = versions."1.11.11"; }
