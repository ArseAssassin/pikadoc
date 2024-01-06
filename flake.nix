{
  description = "pikadoc CLI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk/master";
    nu-plugin.url = "github:ArseAssassin/pikadoc-nushell-plugins";
    nu-source = {
      url = "github:nushell/nushell";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, nu-plugin, nu-source }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          version-number = "0.1.0-${if (self ? rev) then self.rev else "dirty"}";
        in
        rec {
          packages.pikadoc =
            let
              src = ./.;
              bin = pkgs.writeScript "pikadoc" ''
                #!/usr/bin/env nix-shell
                #! nix-shell -i bash -p bash

                PATH=$PATH:${pkgs.pandoc}/bin:${pkgs.nushell}/bin:${pkgs.mdcat}/bin:${pkgs.groff}/bin
                export PKD_PATH="${src}/doc"
                export PKD_VERSION=${version-number}
                mkdir -p $HOME"/.config/pikadoc"

                touch $HOME"/.config/pikadoc/plugin.nu"

                CONFIG=$HOME"/.config/pikadoc/config.nu"
                if [ ! -f "$CONFIG" ]; then
                  cat ${nu-source}/crates/nu-utils/src/sample_config/default_config.nu|sed "s/show_banner: true/show_banner: false/g" > $CONFIG
                fi

                nu -e "register ${nu-plugin.packages.${system}.nu_plugin_query}/bin/nu_plugin_query; use $PKD_PATH; source $PKD_PATH/../init.nu; $*" --plugin-config $HOME"/.config/pikadoc/plugin.nu"
              '';
            in pkgs.stdenv.mkDerivation {
              buildInputs = [];
              name = "pikadoc";
              version = version-number;
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