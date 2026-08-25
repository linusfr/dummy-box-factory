{ pkgs ? import <nixpkgs> { config = {}; } }:
pkgs.mkShell {
  packages = [
    pkgs.openscad     # exports the STLs and the preview renders
    pkgs.python3      # svg2dxf.py needs no third-party packages
    pkgs.just
    pkgs.prek
    pkgs.ruff
    pkgs.yamllint
  ];

  # `just` picks this up, so recipes work without openscad on PATH
  shellHook = ''
    export OPENSCAD=${pkgs.openscad}/bin/openscad
  '';
}
