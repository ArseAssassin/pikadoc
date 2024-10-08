{
  description = "pikadoc CLI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nu-source = {
      url = "github:nushell/nushell";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nu-source }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          version-number = "1.0.0RC1-${if (self ? rev) then self.rev else "dirty"}";
        in
        rec {
          packages.pikadoc =
            let
              src = ./.;
              pkd-path = "${src}/doc";
              bootstrap = pkgs.writeScript "bootstrap.nu" ''
                export use ${pkd-path}
                source ${pkd-path}/../init.nu
              '';
              bin = pkgs.writeScript "pikadoc" ''
                #!/usr/bin/env nix-shell
                #! nix-shell -i bash -p bash

                PATH=$PATH:${pkgs.pandoc}/bin:${pkgs.nushell}/bin:${pkgs.glow}/bin:${pkgs.groff}/bin:${pkgs.html-xml-utils}/bin:${pkgs.xmlstarlet}/bin:${pkgs.html-tidy}/bin
                export PKD_PATH="${src}/doc"
                export PKD_TEMP="/tmp/pikadoc"
                export PKD_VERSION=${version-number}
                export PKD_HOME=${src}
                export PKD_CONFIG_HOME=$HOME"/.config/pikadoc"

                mkdir -p $PKD_CONFIG_HOME

                CONFIG=$PKD_CONFIG_HOME"/config.nu"
                if [ ! -f "$CONFIG" ]; then
                  cat ${nu-source}/crates/nu-utils/src/sample_config/default_config.nu|sed "s/show_banner: true/show_banner: false/g" > $CONFIG
                fi

                COMMAND=$*
                if [ "$1" = "-c" ] || [ "$1" = "--command" ]; then
                  COMMAND=$2
                  COMMAND_FLAG="-c"
                else
                  COMMAND_FLAG="-e"
                fi

                ${pkgs.nushell}/bin/nu --config $CONFIG $COMMAND_FLAG "source ${bootstrap}; $COMMAND"
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