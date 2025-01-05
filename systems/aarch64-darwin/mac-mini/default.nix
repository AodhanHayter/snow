{ pkgs
, config
, lib
, channel
, ...
}:
with lib;
with lib.modernage; {
  modernage = {
    user = {
      name = "aodhanhayter";
    };

    prototype = {
      workstation = enabled;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
