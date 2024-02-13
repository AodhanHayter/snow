{ pkgs
, config
, lib
, channel
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./hardware.nix ];

  modernage = {
    prototype = {
      workstation = enabled;
    };
  };

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2048;
      cores = 2;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
