{ options
, config
, lib
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.kubernetes;
in
{
  options.modernage.kubernetes = with types; {
    enable = mkBoolOpt false "Whether or not to enable kubernetes configuration";
    role = mkOpt (enum [ "master" "node" ]) "node" "The role this kubernetes machine should take";
  };

  config = mkIf cfg.enable {
    services.kubernetes = {
      role = [ cfg.role ];
    };
  };
}
