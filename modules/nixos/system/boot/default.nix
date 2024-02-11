{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.system.boot;
in
{
  options.modernage.system.boot = with types; {
    enable = mkBoolOpt false "Whether or not to enable booting.";
  };

  config = mkIf cfg.enable {
    boot.loader.timeout = 10;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 15;
    boot.loader.systemd-boot.consoleMode = "auto";
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";


    # https://github.com/NixOS/nixpkgs/blob/c32c39d6f3b1fe6514598fa40ad2cf9ce22c3fb7/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix#L66
    boot.loader.systemd-boot.editor = false;
  };
}
