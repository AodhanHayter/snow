{ channels, ... }:
final: prev:
let
  # shortcut: Horizon still needs GTK 2; remove when upstream drops that dependency.
  horizonPkgs = import channels.unstable.path {
    system = prev.stdenv.hostPlatform.system;
    config = channels.unstable.config // {
      problems.handlers."gtk+".broken = "warn";
    };
  };
in
{
  inherit (horizonPkgs) omnissa-horizon-client;
}
