{
  description = "pikadoc CLI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk/master";
    nushell = {
      url = "git+file:///home/tuomas/projects/nushell";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nushell, naersk }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        rec {
          packages.nu_plugin_query =
            let
              naersk' = pkgs.callPackage naersk {};
            in naersk'.buildPackage {
              src = ./.;
            };

          packages.pikadoc =
            let
              bin = pkgs.writeScript "pikadoc" ''
                #!/usr/bin/env nix-shell
                #! nix-shell -i bash -p bash --pure

                PATH=$PATH:${pkgs.pandoc}/bin:${pkgs.nushell}/bin
                HOME=$HOME"/.config/pikadoc"
                nu -e "register ${packages.nu_plugin_query}/bin/nu_plugin_query"
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