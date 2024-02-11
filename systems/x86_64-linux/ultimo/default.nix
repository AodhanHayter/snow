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
}
