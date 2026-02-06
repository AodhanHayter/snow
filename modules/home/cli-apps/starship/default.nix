{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.starship;
in
{
  options.modernage.cli-apps.starship = {
    enable = mkBoolOpt false "Whether or not to install and configure starship prompt.";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      settings = {
        add_newline = true;
        format = "$directory$git_branch$git_status$nix_shell\n$character";

        character = {
          success_symbol = "[❯](purple)";
          error_symbol = "[❯](red)";
          vimcmd_symbol = "[❮](green)";
        };

        directory = {
          style = "blue";
          truncation_length = 8;
          truncate_to_repo = false;
        };

        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };

        git_status = {
          format = "[ $all_status$ahead_behind]($style)";
          style = "yellow";
          modified = "*";
          staged = "+";
          untracked = "?";
          stashed = "≡";
          ahead = "⇡";
          behind = "⇣";
          diverged = "⇡⇣";
          deleted = "";
          renamed = "";
          conflicted = "!";
        };

        nix_shell = {
          format = " [$symbol]($style)";
          symbol = "❄";
          impure_msg = "";
          pure_msg = "";
          style = "blue";
        };
      };
    };
  };
}
