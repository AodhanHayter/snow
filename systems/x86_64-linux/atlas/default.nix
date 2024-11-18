{ lib
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./disk-config.nix ];

  modernage = {
    prototype = {
      lab-node = enabled;
    };

    services = {
      kubernetes = {
        enable = true;
        role = "master";
      };
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
