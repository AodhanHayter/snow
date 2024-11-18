{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.prototype.lab-node;
in
{
  options.modernage.prototype.lab-node = with types; {
    enable = mkBoolOpt false "Whether or not to enable the lab-node prototype.";
  };

  config = mkIf cfg.enable {
    modernage = {
      nix = enabled;

      tools = {
        git = enabled;
      };

      hardware = {
        networking = enabled;
        beelink-eq13 = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
        xkb = enabled;
      };

      cli-apps = {
        neovim = enabled;
        tmux = enabled;
      };

      services = {
        openssh = enabled;
        avahi = enabled;
      };

      security = {
        doas = enabled;
      };
    };
  };
}
