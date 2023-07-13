{
  description = "Simple AWS EC2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
  };

  outputs = { self, nixpkgs, cachix-deploy-flake }:
    let
      pkgs = import nixpkgs {};
      cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
    in {
      defaultPackage = cachix-deploy-lib.spec {
        agents = {
          myagent = cachix-deploy-lib.nixos {
            # TODO: set the hostname
          };
        };
      };
    };
}
