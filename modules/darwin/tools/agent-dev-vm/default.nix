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
    guestSystem = builtins.replaceStrings [ "-darwin" ] [ "-linux" ] system;
    mkLauncher = avm.mkVfkitLauncher;
    resolveKeys = vmDef:
      if vmDef.authorizedKeys != [ ] then vmDef.authorizedKeys
      else config.modernage.security.ssh.authorizedKeys;
    isDarwin = true;
  });
}
