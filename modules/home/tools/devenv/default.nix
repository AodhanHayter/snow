{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.devenv;
  devenv = "${pkgs.devenv}/bin/devenv";
in
{
  options.modernage.tools.devenv = with types; {
    enable = mkBoolOpt false "Whether or not to enable devenv.";
  };

  # inlined instead of programs.devenv: that module is master-only,
  # and tracking home-manager master mismatches nixpkgs 26.05.
  config = mkIf cfg.enable {
    home.packages = [ pkgs.devenv ];

    programs = {
      fish.interactiveShellInit = mkAfter "${devenv} hook fish | source";
      zsh.initContent = mkAfter ''eval "$(${devenv} hook zsh)"'';
    };
  };
}
