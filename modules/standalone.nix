{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ./rig.nix ];

  options = {
    name = mkOption {
      type = types.str;
      description = "Rig name, used as the directory under GT_ROOT.";
    };

    defaultAgent = mkOption {
      type = types.str;
      default = "claude";
      description = "Default agent type for the rig.";
    };
  };
}
