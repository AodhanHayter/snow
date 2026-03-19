{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.hardware.rgb;

  disable-rgb = pkgs.writeShellScript "disable-rgb" ''
    NUM_DEVICES=$(${pkgs.openrgb}/bin/openrgb --noautoconnect --list-devices | ${pkgs.gnugrep}/bin/grep -cE '^[0-9]+: ')
    for i in $(seq 0 $(($NUM_DEVICES - 1))); do
      ${pkgs.openrgb}/bin/openrgb --noautoconnect --device "$i" --mode direct --color 000000
    done
  '';
in
{
  options.modernage.hardware.rgb = with types; {
    enable = mkBoolOpt false "Whether or not to enable RGB lighting control.";
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
    hardware.i2c.enable = true;
    services.udev.packages = [ pkgs.openrgb ];

    systemd.services.disable-rgb = {
      description = "Disable all RGB lighting";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = disable-rgb;
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      };
    };
  };
}
