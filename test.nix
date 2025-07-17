{ pkgs ? import <nixpkgs> { }, }:
let srcs = (import ./nix/versions.nix { inherit pkgs; })."1.11.11";
in pkgs.callPackage ./nix/buildPanel.nix { inherit srcs; }
