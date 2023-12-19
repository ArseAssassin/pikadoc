{
  description = "pikadoc CLI";

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

        in
        rec {
          devShells.default = pkgs.mkShell {
            packages = [pkgs.nushell pkgs.pandoc];
          };

          packages.pikadoc =
            let
              bin = pkgs.writeScript "ldoc" ''
                #!/usr/bin/env nix-shell
                #! nix-shell -i bash -p bash

                PATH=$PATH:${pkgs.pandoc}/bin
                nu -e "source ${nu-fns}"
              '';
            in pkgs.stdenv.mkDerivation {
              buildInputs = [pkgs.pandoc];
              name = "pikadoc";
              version = "0.1.0";
              src = ./.;
              installPhase = ''
                mkdir -p $out/bin
                ln -s ${bin} $out/bin/pikadoc
              '';
            };

          packages.default = packages.pikadoc;
        }
      );
}