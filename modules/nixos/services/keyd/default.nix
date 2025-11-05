{ lib, config, pkgs, ... }:

with lib;
with lib.modernage;
let
  cfg = config.modernage.services.keyd;
in
{
  options.modernage.services.keyd = with types; {
    enable = mkBoolOpt false "Whether to enable keyd for keyboard remapping";
  };

  config = mkIf cfg.enable {
    # Enable the keyd service
    services.keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ]; # Apply to all keyboards
          settings = {
            main = {
              # Caps Lock acts as Escape on tap, Control on hold
              # This is already handled by interception-tools, but we can keep it here too
              capslock = "overload(control, esc)";
            };

            # Meta (Super/Windows key) layer for macOS-style shortcuts
            # When holding Meta (Super), these keys send their Control equivalents
            "meta" = {
              # Basic editing shortcuts
              "c" = "C-c"; # Copy
              "x" = "C-x"; # Cut
              "v" = "C-v"; # Paste
              "a" = "C-a"; # Select All
              "z" = "C-z"; # Undo
              "y" = "C-y"; # Redo (alternative to Shift+Z)

              # File operations
              "s" = "C-s"; # Save
              "o" = "C-o"; # Open
              "n" = "C-n"; # New
              "p" = "C-p"; # Print

              # Search operations
              "f" = "C-f"; # Find
              "g" = "C-g"; # Find Next
              "r" = "C-r"; # Replace/Refresh

              # Tab management
              "t" = "C-t"; # New Tab
              "w" = "C-w"; # Close Tab/Window

              # Text navigation with arrow keys
              "left" = "C-left"; # Word left
              "right" = "C-right"; # Word right
              "backspace" = "C-u"; # Delete to beginning of line (macOS Cmd+Backspace behavior)

              # Home/End with up/down arrows (macOS style)
              "up" = "C-home"; # Beginning of document
              "down" = "C-end"; # End of document
            };

            # Meta+Shift layer for additional shortcuts
            "meta+shift" = {
              "z" = "C-S-z"; # Redo
              "g" = "C-S-g"; # Find Previous
              "t" = "C-S-t"; # Reopen Tab
              "n" = "C-S-n"; # New Window
              "p" = "C-S-p"; # Print Preview/Settings
            };

            # Alt layer for word operations (macOS Option key behavior)
            "alt" = {
              "backspace" = "C-backspace"; # Delete word (macOS Option+Backspace)
            };

            # Meta+Alt layer for word selection
            "meta+alt" = {
              "left" = "C-S-left"; # Select word left
              "right" = "C-S-right"; # Select word right
            };
          };
        };
      };
    };

    # Ensure keyd starts early in the boot process
    systemd.services.keyd = {
      wantedBy = [ "sysinit.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 1;
      };
    };
  };
}