{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    scope = mkOption {
      type = types.str;
      description = "Scope the agent operates in (e.g. 'rig', 'town', 'project').";
    };

    provider = mkOption {
      type = types.str;
      default = "claude";
      description = "AI provider for this agent (e.g. 'claude', 'openai').";
    };

    maxConcurrent = mkOption {
      type = types.ints.positive;
      default = 1;
      description = "Maximum number of concurrent instances of this agent.";
    };
  };
}
