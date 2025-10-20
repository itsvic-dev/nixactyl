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
      vendorHash = "sha256-b+h6D2MdT1cDF7B+V4qsNlr3SvHCXMnz2R0LW9YRUl8=";
      prebuiltAssets = true;
    };
  };
in versions // { latest = versions."1.11.11"; }
