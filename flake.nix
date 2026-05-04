{
  description = "Nix packaging and declarative rig configuration for Gas Town";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    gascity-src = {
      url = "github:gastownhall/gascity";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      gascity-src,
    }:
    let
      lib = nixpkgs.lib;
      gastownLib = import ./lib { inherit lib; };

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
            inherit system;
          }
        );
    in
    {
      lib = gastownLib;

      packages = forAllSystems (
        { pkgs, system }:
        let
          gc = pkgs.buildGoModule {
            pname = "gascity";
            version = "1.0.0";
            src = gascity-src;

            subPackages = [ "cmd/gc" ];
            tags = [ "gms_pure_go" ];
            doCheck = false;

            proxyVendor = true;
            vendorHash = lib.fakeHash;

            postPatch = ''
              goVer="$(go env GOVERSION | sed 's/^go//')"
              go mod edit -go="$goVer"
            '';

            env.GOTOOLCHAIN = "auto";

            nativeBuildInputs = [ pkgs.git ];

            meta = with pkgs.lib; {
              description = "Gas City (gc) - unified CLI for Gas Town and Beads";
              homepage = "https://github.com/gastownhall/gascity";
              license = licenses.mit;
              mainProgram = "gc";
            };
          };
        in
        {
          inherit gc;
          default = gc;
        }
      );

      apps = forAllSystems (
        { pkgs, system }:
        let
          rig = gastownLib.mkRig {
            inherit pkgs;
            gcPackage = self.packages.${system}.gc;
            config = {
              name = "gt_nix";
              path = ".";
              gitUrl = "git@github.com:keithschulze/gastown.nix.git";
            };
          };
        in
        {
          gc = {
            type = "app";
            program = "${self.packages.${system}.gc}/bin/gc";
          };
          mayorAttach = {
            type = "app";
            program = "${rig.mayorAttach}/bin/gt-mayor-attach";
          };
          gtUp = {
            type = "app";
            program = "${rig.gtUp}/bin/gt-up";
          };
          gtDown = {
            type = "app";
            program = "${rig.gtDown}/bin/gt-down";
          };
          test = {
            type = "app";
            program = "${rig.test}/bin/gt-test-rig";
          };
          default = self.apps.${system}.gc;
        }
      );

      devShells = forAllSystems (
        { pkgs, system }:
        {
          default = pkgs.mkShell {
            buildInputs = [
              self.packages.${system}.gc
              pkgs.dolt
            ];
          };
        }
      );

      checks = forAllSystems (
        { pkgs, system }:
        {
          eval-rig =
            let
              rig = gastownLib.mkRig {
                inherit pkgs;
                gcPackage = self.packages.${system}.gc;
                config = {
                  name = "my-rig";
                  path = "rigs/my-rig";
                  gitUrl = "git@github.com:test/standalone.git";
                };
              };
            in
            pkgs.runCommand "check-eval-rig" { nativeBuildInputs = [ pkgs.jq ]; } ''
              # rigs.json has single entry
              jq -e '.version == 1' ${rig.configDir}/rigs.json
              jq -e '.rigs["my-rig"].git_url == "git@github.com:test/standalone.git"' ${rig.configDir}/rigs.json
              jq -e '.rigs["my-rig"].path == "rigs/my-rig"' ${rig.configDir}/rigs.json

              # settings/config.json
              jq -e '.type == "town-settings"' ${rig.configDir}/settings/config.json
              jq -e '.default_agent == "claude"' ${rig.configDir}/settings/config.json

              # rig config.json
              jq -e '.type == "rig"' ${rig.rigConfig}
              jq -e '.name == "my-rig"' ${rig.rigConfig}
              jq -e '.git_url == "git@github.com:test/standalone.git"' ${rig.rigConfig}

              # configDir structure
              test -f ${rig.configDir}/rigs.json
              test -f ${rig.configDir}/settings/config.json
              test -f ${rig.configDir}/my-rig/config.json

              echo "Standalone rig checks passed"
              touch $out
            '';

          eval-rig-minimal =
            let
              rig = gastownLib.mkRig {
                inherit pkgs;
                gcPackage = self.packages.${system}.gc;
                config = {
                  name = "minimal-rig";
                  path = "rigs/minimal";
                  gitUrl = "git@github.com:test/minimal-rig.git";
                };
              };
            in
            pkgs.runCommand "check-eval-rig-minimal" { nativeBuildInputs = [ pkgs.jq ]; } ''
              # Verify basic config
              jq -e '.rigs["minimal-rig"].git_url == "git@github.com:test/minimal-rig.git"' ${rig.configDir}/rigs.json

              jq -e '.name == "minimal-rig"' ${rig.rigConfig}
              jq -e '.default_branch == "main"' ${rig.rigConfig}

              echo "Minimal standalone rig checks passed"
              touch $out
            '';

          eval-rig-pure =
            let
              cfg = gastownLib.evalRig {
                config = {
                  name = "pure-rig";
                  path = "rigs/pure";
                  gitUrl = "git@github.com:test/pure-rig.git";
                };
              };
            in
            pkgs.runCommand "check-eval-rig-pure" { } ''
              [[ "${cfg.name}" == "pure-rig" ]]
              [[ "${cfg.path}" == "rigs/pure" ]]
              [[ "${cfg.gitUrl}" == "git@github.com:test/pure-rig.git" ]]
              [[ "${cfg.defaultBranch}" == "main" ]]

              echo "Pure rig evaluation checks passed"
              touch $out
            '';

          check-integration =
            let
              rig = gastownLib.mkRig {
                inherit pkgs;
                gcPackage = self.packages.${system}.gc;
                config = {
                  name = "test-rig";
                  path = "rigs/test";
                  gitUrl = "git@github.com:test/integration.git";
                };
              };
            in
            pkgs.runCommand "check-integration" {
              nativeBuildInputs = [ pkgs.git pkgs.jq self.packages.${system}.gc ];
            } ''
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"
              git config --global user.email "test@test.com"
              git config --global user.name "Test"
              ${rig.test}/bin/gt-test-rig
              touch $out
            '';
        }
      );

      templates.default = {
        path = ./templates/default;
        description = "Embeddable Gas Town rig configuration";
      };
    };
}
