{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    workspace = {
      name = mkOption {
        type = types.str;
        description = "City name, used as the workspace identifier.";
      };

      provider = mkOption {
        type = types.str;
        default = "local";
        description = "Workspace provider backend.";
      };
    };

    session = {
      provider = mkOption {
        type = types.str;
        default = "tmux";
        description = "Session multiplexer provider.";
      };

      concurrentPerAgent = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Maximum concurrent sessions per agent.";
      };
    };

    beads = {
      provider = mkOption {
        type = types.str;
        default = "dolt";
        description = "Beads storage provider.";
      };

      prefix = mkOption {
        type = types.str;
        default = "hq";
        description = "Bead ID prefix for city-level beads.";
      };
    };

    daemon = {
      patrolInterval = mkOption {
        type = types.str;
        default = "30s";
        description = "How often the daemon checks for stalled agents.";
      };

      maxRestarts = mkOption {
        type = types.ints.unsigned;
        default = 3;
        description = "Maximum automatic restarts per agent before giving up.";
      };

      shutdownTimeout = mkOption {
        type = types.str;
        default = "60s";
        description = "Grace period before force-killing agents on shutdown.";
      };
    };

    rigs = mkOption {
      type = types.attrsOf (types.submodule (
        { name, config, ... }:
        {
          imports = [ ./rig.nix ];

          options = {
            name = mkOption {
              type = types.str;
              default = name;
              description = "Rig name, defaults to the attribute key.";
            };

            mayorCrew = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Which crew member mayorAttach uses. When null and exactly one
                crew member is declared, that member is auto-selected.
              '';
            };
          };

          config =
            let
              crewNames = builtins.attrNames config.crew;
              crewCount = builtins.length crewNames;
            in
            lib.mkIf (crewCount == 1) {
              mayorCrew = lib.mkDefault (builtins.head crewNames);
            };
        }
      ));
      default = { };
      description = "Rig definitions for this city.";
    };
  };
}
