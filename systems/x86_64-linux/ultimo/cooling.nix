{ pkgs, ... }:
let
  krakenCurve = pkgs.writeShellApplication {
    name = "ultimo-kraken-curve";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./kraken-curve.sh;
  };
in
{
  # Detected NCT6798D on this N7 B550; retain its existing firmware fan curves.
  boot.kernelModules = [ "nct6775" ];
  environment.systemPackages = [ pkgs.lm_sensors ];

  # Match the driver, not a boot-dependent hwmon number. An empty template
  # instance makes systemd use the escaped sysfs path, including /sys.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hwmon", ATTR{name}=="z53", TAG+="systemd", ENV{SYSTEMD_WANTS}+="kraken-cooling@.service"
  '';

  systemd.services."kraken-cooling@" = {
    description = "Kraken Z53 onboard coolant curves";
    bindsTo = [ "%i.device" ];
    # Serialize startup writes with the existing OpenRGB oneshot.
    after = [
      "%i.device"
      "disable-rgb.service"
    ];
    unitConfig = {
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${krakenCurve}/bin/ultimo-kraken-curve %f";
      TimeoutStartSec = "30s";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    # No ExecStop: keep cooling during service shutdown. Device removal stops
    # this instance; a new hwmon device starts a new one and reapplies curves.
  };
}
