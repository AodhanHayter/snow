{
  description = "Modern Age";

  inputs = {
    # NixPkgs (nixos-24.11)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # NixPkgs Unstable (nixos-unstable)
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager (release-24.05)
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Support (master)
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # declaritive partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # Snowfall Lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Flake
    flake.url = "github:snowfallorg/flake?ref=v1.4.1";
    flake.inputs.nixpkgs.follows = "unstable";

    # GPG default config
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    ghostty = {
      url = "github:ghostty-org/ghostty/v1.1.0";
    };

    alacritty-themes = {
      url = "github:alacritty/alacritty-theme?ref=master";
      flake = false;
    };

    devenv = {
      url = "github:cachix/devenv?ref=v1.6";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:AodhanHayter/opencode-flake";
    };
  };


  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "modernage";
            title = "Modern Age";
          };

          namespace = "modernage";
        };
      };
    in
    lib.mkFlake
      {
        channels-config = {
          allowUnfree = true;
        };

        overlays = with inputs; [
          flake.overlays.default
        ];

        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
        ];

        systems.modules.darwin = with inputs; [
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
        ];

        deploy = lib.mkDeploy { inherit (inputs) self; };

        checks = builtins.mapAttrs (system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
      };
}

