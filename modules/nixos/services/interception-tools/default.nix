{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.interception-tools;
in
{
  options.modernage.services.interception-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable interception-tools configuration.";
  };

  config = mkIf cfg.enable
    {
      services.interception-tools =
        let
          dfkConfig = pkgs.writeText "dual-function-keys.yaml" ''
            MAPPINGS:
              - KEY: KEY_CAPSLOCK
                TAP: KEY_ESC
                HOLD: KEY_LEFTCTRL
          '';
        in
        {
          enable = true;
          plugins = mkForce [ pkgs.interception-tools-plugins.dual-function-keys ];
          udevmonConfig = ''
            - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dfkConfig} | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
              DEVICE:
                NAME: "Unicomp Inc Unicomp R7_2_Mac_10x_Kbrd_v7_47"
                EVENTS:
                  EV_KEY: [[KEY_CAPSLOCK, KEY_ESC, KEY_LEFTCTRL]]
          '';
        };
    };
}
