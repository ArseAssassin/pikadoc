{
  description = "pikadoc CLI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk/master";
    nu-plugin.url = "path:./nu-plugins";
  };

  outputs = { self, nixpkgs, flake-utils, naersk, nu-plugin }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        rec {
          # Devshell not necessary, just do `nix run #pikadoc`

          # devShells.default = pkgs.mkShell {
          #   packages = [
          #     pkgs.pandoc
          #     pkgs.nushell
          #     pkgs.mdcat
          #     pkgs.groff
          #   ];

          #   shellHook = ''
          #     export PKD_PATH=`pwd`/doc
          #     nu -e "use "$PKD_PATH" ; source "$PKD_PATH"/../init.nu" --plugin-config $HOME"/.config/pikadoc/plugin.nu"
          #   '';
          # };

          packages.nu_plugin_query =
            let
              naersk' = pkgs.callPackage naersk {};
            in naersk'.buildPackage {
              src = ./.;
            };

          packages.pikadoc =
            let
              src = ./.;
              bin = pkgs.writeScript "pikadoc" ''
                #!/usr/bin/env nix-shell
                #! nix-shell -i bash -p bash

                PATH=$PATH:${pkgs.pandoc}/bin:${pkgs.nushell}/bin:${pkgs.mdcat}/bin:${pkgs.groff}/bin
                export PKD_PATH="${src}/doc"
                mkdir -p $HOME"/.config/pikadoc"

                touch $HOME"/.config/pikadoc/plugin.nu"
                nu -e "register ${nu-plugin.packages.${system}.nu_plugin_query}/bin/nu_plugin_query; use $PKD_PATH; source $PKD_PATH/../init.nu" --plugin-config $HOME"/.config/pikadoc/plugin.nu"
              '';
            in pkgs.stdenv.mkDerivation {
              buildInputs = [];
              name = "pikadoc";
              version = "0.1.0";
              src = ./.;
              installPhase = ''
                mkdir -p $out/bin
                cp -r $src/doc $out/doc
                ln -s ${bin} $out/bin/pikadoc
              '';
            };

          packages.default = packages.pikadoc;
        }
      );
}