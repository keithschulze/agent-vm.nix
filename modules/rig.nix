{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    path = mkOption {
      type = types.str;
      description = "Filesystem path to the rig's working directory.";
    };

    gitUrl = mkOption {
      type = types.str;
      description = "Git URL for the rig's repository.";
    };

    defaultBranch = mkOption {
      type = types.str;
      default = "main";
      description = "Default branch name.";
    };
  };
}
