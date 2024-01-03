{
  description = "Nushell Web Query Plugin";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk/master";
  };

  outputs = { self, nixpkgs, flake-utils, naersk }:
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

          packages.default = packages.nu_plugin_query;
        }
      );
}