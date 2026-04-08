{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.agent-dev-vm;
in
{
  options.modernage.tools.agent-dev-vm = with types; {
    enable = mkBoolOpt false "Whether to enable agent development VMs.";
    vms = mkOpt (attrsOf avm.vmSubmodule) { } "Named VM definitions.";
  };

  config = mkIf cfg.enable (avm.mkModuleConfig {
    inherit cfg pkgs inputs;
    guestSystem = system;
    mkLauncher = avm.mkQemuLauncher;
    resolveKeys = vmDef:
      if vmDef.authorizedKeys != [ ] then vmDef.authorizedKeys
      else [ ];
    isDarwin = false;
  });
}
