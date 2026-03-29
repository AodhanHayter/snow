{ options
, config
, pkgs
, lib
, inputs
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.security.ssh;

  authorizedKeysText = concatStringsSep "\n" cfg.authorizedKeys + "\n";
in
{
  options.modernage.security.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to install openssh"; # macOS now ships with FIDO2/yubikey support; Nix openssh causes firewall issues
    server = mkBoolOpt false "Whether to enable Remote Login (SSH server).";
    authorizedKeys = mkOpt (listOf str) [ ] "Public keys to authorize for the primary user.";
  };

  config = let
    user = config.modernage.user.name;
    authorizedKeysDir = "/etc/ssh/authorized_keys.d";
    authorizedKeysPath = "${authorizedKeysDir}/${user}";
    authorizedKeysSrc = pkgs.writeText "authorized_keys-${user}" authorizedKeysText;
  in mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ openssh ];
    })
    (mkIf cfg.server {
      services.openssh = {
        enable = true;
        extraConfig = ''
          AuthorizedKeysFile ${authorizedKeysDir}/%u
        '';
      };
    })
    (mkIf (cfg.authorizedKeys != [ ]) {
      system.activationScripts.postActivation.text = ''
        mkdir -p ${authorizedKeysDir}
        install -m 644 -o ${user} ${authorizedKeysSrc} ${authorizedKeysPath}
      '';
    })
  ];
}
