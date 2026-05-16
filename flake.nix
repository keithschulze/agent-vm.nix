{
  description = "Run Claude Code and beads inside an isolated NixOS microVM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = inputs@{ self, nixpkgs, microvm, llm-agents, utils }:
    with utils.lib; eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Guests are always Linux; map a host system to its matching guest arch.
        guestOf = {
          "aarch64-darwin" = "aarch64-linux";
          "aarch64-linux"  = "aarch64-linux";
          "x86_64-darwin"  = "x86_64-linux";
          "x86_64-linux"   = "x86_64-linux";
        };

        hypervisorOf = {
          "aarch64-darwin" = "vfkit";
          "aarch64-linux"  = "aarch64-linux";
          "x86_64-darwin"  = "vfkit";
          "x86_64-linux"   = "x86_64-linux";
        };

        agentLib = import ./lib { inherit inputs; };

        # Dogfood VM used by `nix run .#vm` so this repo is testable on its own.
        mkDogfood = hostSystem:
          agentLib.mkAgentVM {
            hostPkgs = pkgs;
            system = guestOf.${hostSystem};
            hostname = "agent-vm";
            username = "agent";
            hypervisor = hypervisorOf.${hostSystem};
            # No shares beyond the mandatory ro-store — the dogfood VM is
            # self-contained. Real users mount $HOME paths via the templates.
          };
      in
      {
        lib = agentLib;

        nixosModules = {
          default = import ./modules/agent-vm.nix;
          agent-vm = import ./modules/agent-vm.nix;
        };

        packages = let vm = mkDogfood system; in {
          default = vm.config.microvm.declaredRunner;
          vm = vm.config.microvm.declaredRunner;
        };

        templates.default = {
          path = ./templates/default;
          description = "Example flake consuming agent-vm.nix with host mounts.";
        };

        # Exposed so external tools can refer to the dogfood guest config.
        nixosConfigurations.dogfood = mkDogfood system;
      });
}
