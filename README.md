# gastown.nix

__WARNING: This is vibe coded using gastown for my own learning. DO NOT USE.__

Declarative Gas Town rig and crew configuration using the Nix module system.

## Usage

Add `gastown.nix` as a flake input and use `lib.mkRig` to embed a Gas Town rig
directly inside your project flake. This is the recommended pattern for
single-rig setups where the project itself hosts the configuration.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gastown-nix.url = "github:keithschulze/gastown.nix";
  };

  outputs = { nixpkgs, gastown-nix, ... }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    rig = gastown-nix.lib.mkRig {
      inherit pkgs;
      gtPackage = gastown-nix.packages.x86_64-linux.gt;
      bdPackage = gastown-nix.packages.x86_64-linux.bd;  # optional
      config = {
        name = "my-project";
        gitUrl = "git@github.com:org/project.git";
        beads.prefix = "mp";
        crew.alice = {
          role = "developer";
          githubUsername = "alice-gh";
        };
      };
    };
  in {
    # rig.config       - evaluated configuration
    # rig.rigConfig    - rig config.json derivation
    # rig.rigSettings  - rig settings.json derivation
    # rig.crewConfigs  - per-member config.json derivations
    # rig.configDir    - combined directory tree
    # rig.activate     - script to write configs into GT_ROOT
    # rig.mayorAttach  - script to activate .gt/ and run gt mayor attach
    apps.mayorAttach = {
      type = "app";
      program = "${rig.mayorAttach}/bin/gt-mayor-attach";
    };
  };
}
```

`mkRig` accepts:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pkgs` | nixpkgs | yes | Nixpkgs package set |
| `gtPackage` | derivation | yes | `gt` CLI package |
| `bdPackage` | derivation | no | `bd` CLI package |
| `modules` | list | no | Extra NixOS-style modules |
| `config` | attrset | no | Inline configuration |

`mayorAttach` discovers the project root via `git rev-parse`, writes
generated configs into `.gt/`, creates crew state, and runs
`gt mayor attach`.

## Pure evaluation

Use `evalRig` when you only need the evaluated config without derivations:

```nix
cfg = gastown-nix.lib.evalRig {
  config = {
    name = "my-project";
    gitUrl = "git@github.com:org/project.git";
    beads.prefix = "mp";
    crew.alice = { role = "developer"; };
  };
};
# cfg.name         => "my-project"
# cfg.mayorCrew    => "alice" (auto-selected, single crew member)
```

## Activation

The `activate` output is a script that writes generated configs into a
Gas Town directory:

```bash
GT_ROOT=~/my-project/.gt nix run .#activate
```

## Rig options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | *required* | Rig name, used as the directory under GT_ROOT |
| `gitUrl` | string | *required* | Git URL for the rig's repository |
| `defaultBranch` | string | `"main"` | Default branch name |
| `beads.prefix` | string | *required* | Issue ID prefix |
| `maxPolecats` | positive int | `10` | Max concurrent polecat workers |
| `autoRestart` | bool | `true` | Auto-restart agents on failure |
| `autoStartOnUp` | bool | `false` | Start agents when rig comes up |
| `defaultFormula` | string | `"mol-polecat-work"` | Default workflow formula |
| `dnd` | bool | `false` | Do Not Disturb mode |
| `polecatBranchTemplate` | string or null | `null` | Custom polecat branch naming |
| `priorityAdjustment` | int | `0` | Priority offset for dispatch |
| `mayorCrew` | string or null | `null` | Which crew member `mayorAttach` uses (auto-selected when exactly one crew member) |
| `defaultAgent` | string | `"claude"` | Default agent type |
| `crew` | attrsOf { role, githubUsername, email } | `{}` | Crew member definitions |

## Running checks

```bash
nix flake check
```
