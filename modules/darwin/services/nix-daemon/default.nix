{ lib, config, ... }:

let
  inherit (lib) types mkIf;
  inherit (lib.modernage) mkOpt enabled;

  cfg = config.modernage.services.nix-daemon;
in
{
  options.modernage.services.nix-daemon = {
    enable = mkOpt types.bool true "Whether to enable the Nix daemon.";
  };

  config = mkIf cfg.enable {
    services.nix-daemon = enabled;
  };
}
