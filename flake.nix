{
  description = "todo.yaml CLI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          nodejs = pkgs.nodejs_20;
          nu-fns = ./doc.nu;
          bin = pkgs.writeScript "ldoc" ''
            #!/usr/bin/env nix-shell
            #! nix-shell -i bash -p bash

            nu -e "source ${nu-fns}"
          '';
        in
        rec {
          devShells.default = pkgs.mkShell {
            packages = [pkgs.nushell packages.ldoc-html-to-md];
          };

          packages.ldoc-html-to-md = pkgs.buildNpmPackage rec {
            nodejs = pkgs.nodejs_20;

            npmDepsHash = "sha256-ang52ZTO28f37LTlR+GJxKf9CPh4AVaahr34jcvvfQo=";

            name = "ldoc-html-to-md";
            version = "0.1.0";
            src = ./apps/ldoc-html-to-md;

            installPhase = ''
              mkdir -p $out/bin
              mv * $out/lib/node_modules/lightdocs/* $out
            '';
          };

          packages.ldoc = pkgs.stdenv.mkDerivation {
            name = "ldoc";
            version = "0.1.0";
            src = ./.;
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${bin} $out/bin/ldoc
            '';
          };

          packages.default = packages.ldoc;
        }
      );
}