{
  description = "Nix packaging for Gas Town (gt) and Beads (bd)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    gastown-src = {
      url = "github:gastownhall/gastown";
      flake = false;
    };

    beads-src = {
      url = "github:gastownhall/beads";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      gastown-src,
      beads-src,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
            inherit system;
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, system }:
        let
          bdBase = pkgs.buildGoModule {
            pname = "beads";
            version = "1.0.3";
            src = beads-src;

            subPackages = [ "cmd/bd" ];
            tags = [ "gms_pure_go" ];
            doCheck = false;

            proxyVendor = true;
            vendorHash = "sha256-FjO7mUTB9FJL5ShVzEj+dEr1Hpzb23JO5QjNLPc5sLQ=";

            postPatch = ''
              goVer="$(go env GOVERSION | sed 's/^go//')"
              go mod edit -go="$goVer"
            '';

            env.GOTOOLCHAIN = "auto";

            nativeBuildInputs = [ pkgs.git ];

            meta = with pkgs.lib; {
              description = "beads (bd) - issue tracker for AI-supervised coding workflows";
              homepage = "https://github.com/gastownhall/beads";
              license = licenses.mit;
              mainProgram = "bd";
            };
          };

          bd = pkgs.stdenv.mkDerivation {
            pname = "beads";
            version = bdBase.version;
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out/bin
              cp ${bdBase}/bin/bd $out/bin/bd
              ln -s bd $out/bin/beads

              mkdir -p $out/share/fish/vendor_completions.d
              mkdir -p $out/share/bash-completion/completions
              mkdir -p $out/share/zsh/site-functions

              $out/bin/bd completion fish > $out/share/fish/vendor_completions.d/bd.fish
              $out/bin/bd completion bash > $out/share/bash-completion/completions/bd
              $out/bin/bd completion zsh > $out/share/zsh/site-functions/_bd
            '';
            meta = bdBase.meta;
          };

          gt = pkgs.buildGoModule {
            pname = "gt";
            version = "1.0.0";
            src = gastown-src;

            subPackages = [ "cmd/gt" ];
            doCheck = false;

            proxyVendor = true;
            vendorHash = "sha256-ew4YoB1sn6FvPbxs29kqd2BUv/KO5Fy7JWHj/hKPEPs=";

            postPatch = ''
              goVer="$(go env GOVERSION | sed 's/^go//')"
              go mod edit -go="$goVer"
            '';

            env.GOTOOLCHAIN = "auto";

            ldflags = [
              "-s"
              "-w"
              "-X github.com/steveyegge/gastown/internal/cmd.Build=nix"
              "-X github.com/steveyegge/gastown/internal/cmd.BuiltProperly=1"
            ];

            meta = with pkgs.lib; {
              description = "Gas Town - multi-agent orchestration for Claude Code";
              homepage = "https://github.com/gastownhall/gastown";
              license = licenses.mit;
              mainProgram = "gt";
            };
          };
        in
        {
          inherit gt bd;
          default = gt;
        }
      );

      apps = forAllSystems (
        { system, ... }:
        {
          gt = {
            type = "app";
            program = "${self.packages.${system}.gt}/bin/gt";
          };
          bd = {
            type = "app";
            program = "${self.packages.${system}.bd}/bin/bd";
          };
          default = self.apps.${system}.gt;
        }
      );

      devShells = forAllSystems (
        { pkgs, system }:
        {
          default = pkgs.mkShell {
            buildInputs = [
              self.packages.${system}.gt
              self.packages.${system}.bd
            ];
          };
        }
      );
    };
}
