{
  description = "Parametric Netrunner faction deck boxes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.openscad
            pkgs.python3
            pkgs.just
            pkgs.prek
            pkgs.ruff
            pkgs.yamllint
          ];

          shellHook = ''
            export OPENSCAD=${pkgs.openscad}/bin/openscad
          '';
        };
      });
    };
}
