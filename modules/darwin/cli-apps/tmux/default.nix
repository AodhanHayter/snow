{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.cli-apps.tmux;
in
{
  options.modernage.cli-apps.tmux = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable tmux configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      tmux
    ];
  };
}
