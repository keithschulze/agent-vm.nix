{
  description = "Gas Town rig configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    gastown-nix = {
      url = "github:keithschulze/gastown.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gastown-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        gcLib = gastown-nix.lib;
        gcPackage = gastown-nix.packages.${system}.gc;

        packToml = gcLib.mkPack {
          inherit pkgs;
          config = {
            name = "my-project";
            agents = {
              mayor = {
                scope = "town";
                provider = "claude";
                maxConcurrent = 1;
              };
              witness = {
                scope = "rig";
                provider = "claude";
                maxConcurrent = 1;
              };
              polecat = {
                scope = "rig";
                provider = "claude";
                maxConcurrent = 10;
              };
            };
          };
        };

        city = gcLib.mkCity {
          inherit pkgs gcPackage packToml;
          config = {
            workspace.name = "my-project";
            rigs.my-project = {
              path = ".";
              gitUrl = "git@github.com:org/project.git";
            };
          };
        };
      in
      {
        apps.up = {
          type = "app";
          program = "${city.gcUp}/bin/gc-up";
        };

        apps.down = {
          type = "app";
          program = "${city.gcDown}/bin/gc-down";
        };

        apps.attach = {
          type = "app";
          program = "${city.gcAttach}/bin/gc-attach";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            gcPackage
          ];
        };
      }
    );
}
