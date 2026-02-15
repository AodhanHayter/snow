{
  description = "Modern Age";

  inputs = {
    # NixPkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # NixPkgs Unstable (nixos-unstable)
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Support
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # determinate nix
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    };

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

    # GPG default config
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    ghostty = {
      url = "github:ghostty-org/ghostty/v1.1.3";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:AodhanHayter/opencode-flake?ref=fix-builds-for-macos";
    };

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    expert = {
      url = "github:elixir-lang/expert?ref=nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code plugins/skills sources
    anthropics-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };

    cc-marketplace = {
      url = "github:AodhanHayter/claude-code-safety-net?ref=fix/py3.9-incompatible-type-annotations";
      flake = false;
    };

    dev-browser = {
      url = "github:SawyerHood/dev-browser";
      flake = false;
    };

    claude-lsp-plugins = {
      url = "github:AodhanHayter/claude-lsp-plugins";
      flake = false;
    };

    xcode-build-skill = {
      url = "github:pzep1/xcode-build-skill";
      flake = false;
    };

    xclaude-plugin = {
      url = "github:conorluddy/xclaude-plugin";
      flake = false;
    };

    claude-swift-engineering = {
      url = "github:johnrogers/claude-swift-engineering";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = builtins.path {
          path = ./.;
          name = "source";
        };

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
        mcp-servers-nix.overlays.default
      ];

      systems.modules.nixos = with inputs; [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        determinate.nixosModules.default
      ];

      systems.modules.darwin = with inputs; [
        home-manager.darwinModules.home-manager
        determinate.darwinModules.default
      ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
      ];

      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks = builtins.mapAttrs (
        system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy
      ) inputs.deploy-rs.lib;

      # VM configurations for use with claude-vm tool.
      # Each config defines a VM that can be created/started via:
      #   vm create <name> --flake=~/development/snow
      #   vm start <name> --project=<path>
      #
      # Fields:
      #   darwinConfiguration - nix-darwin config from systems/aarch64-darwin/<name>
      #   image - OCI image for base VM (Cirrus macOS images)
      #   readOnlyMounts - host dirs mounted read-only (configs, credentials)
      #   symlinks - VM home symlinks: { ".ssh" = "ssh" } links ~/.ssh -> mount/ssh
      vmConfigurations = {
        claude-agent = {
          # Which darwin config to apply (matches systems/aarch64-darwin/<name>)
          darwinConfiguration = "claude-vm";

          # Base image to use
          image = "ghcr.io/cirruslabs/macos-tahoe-base:latest";

          # Directories to mount read-only from host
          readOnlyMounts = [
            "~/.ssh"
            "~/.gitconfig"
            "~/.config/git"
            "~/.claude"
            "~/.gnupg"
          ];

          # Symlinks to create in VM (VM path -> mount path)
          symlinks = {
            ".ssh" = "ssh";
            ".gitconfig" = "gitconfig/.gitconfig";
            ".claude" = "claude";
            ".gnupg" = "gnupg";
          };
        };
      };
    };
}
