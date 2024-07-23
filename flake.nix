{
  description = "Modern Age";

  inputs = {
    # NixPkgs (nixos-24.05)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # NixPkgs Unstable (nixos-unstable)
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager (release-24.05)
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Support (master)
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

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

    alacritty-themes = {
      url = "github:alacritty/alacritty-theme?ref=master"
      flake = false;
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
    lib.mkFlake {
      channels-config = {
        allowUnfree = true;
      };

      overlays = with inputs; [
        flake.overlays.default
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
      ];

      systems.modules.darwin = with inputs; [
        home-manager.darwinModules.home-manager
      ];
    };
}

