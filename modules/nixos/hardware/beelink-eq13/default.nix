{ options, config, lib, modulesPath, ...}:
with lib;
with lib.modernage; let
  cfg = config.modernage.hardware.beelink-eq13;
in
{
  options.modernage.hardware.beelink-eq13 = with types; {
    enable = mkBoolOpt false "Wheter or not to enable the beelink-eq13 hardware";
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware.nix
  ];

  config = mkIf cfg.enable {
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
