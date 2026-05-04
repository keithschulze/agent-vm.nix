# gastown.nix

__WARNING: This is vibe coded using [gastown](https://github.com/gastownhall/gastown) for my own learning. IT'S NOT FUNCTIONAL, DO NOT USE.__

An embedded, declarative Gas Town rig and crew configuration using the Nix module system.

This is __not__ how Gas Town is supposed to be used. Gas Town's philosophy is to manage many projects (rigs), so this goes squarely against that. As a result, there's a lot of Gas Town functionality that isn't relevant here. A lot is useful though. Once we've learnt what's useful, we can simplify.  

## Usage

__WARNING: You appear to have IGNORED my previous warning. DO NOT PROCEED any further, this is all slop.__

__WARNING: Absolute folly. This is your last and final warning: DO NOT USE THIS!__

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
        path = ".";
        gitUrl = "git@github.com:org/project.git";
      };
    };
  in {
    # rig.config       - evaluated configuration
    # rig.rigConfig    - rig config.json derivation
    # rig.configDir    - combined directory tree
    # rig.mayorAttach  - script to manage full GT lifecycle (up/attach/down)
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

`mayorAttach` manages the full Gas Town lifecycle in a single command:

1. Discovers the project root via `git rev-parse`
2. Writes generated configs into `.gt/`
3. Runs `gt install` to initialize the GT directory structure
4. Runs `gt up` to start all services (Dolt, daemon, agents, etc.)
5. Runs `gt mayor attach` (blocks until detach with Ctrl-B D)
6. Runs `gt down` on exit to tear down all services

A trap ensures `gt down` runs even on unexpected exit.

## Pure evaluation

Use `evalRig` when you only need the evaluated config without derivations:

```nix
cfg = gastown-nix.lib.evalRig {
  config = {
    name = "my-project";
    path = ".";
    gitUrl = "git@github.com:org/project.git";
  };
};
# cfg.name         => "my-project"
# cfg.path         => "."
# cfg.defaultBranch => "main"
```

## Rig options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | *required* | Rig name, used as the directory under GT_ROOT |
| `path` | string | *required* | Filesystem path to the rig's working directory |
| `gitUrl` | string | *required* | Git URL for the rig's repository |
| `defaultBranch` | string | `"main"` | Default branch name |
| `defaultAgent` | string | `"claude"` | Default agent type |

## Running checks

```bash
nix flake check
```
