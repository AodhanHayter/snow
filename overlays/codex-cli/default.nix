{ inputs, ... }:
final: prev:
let
  base = inputs.codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;

  platform =
    {
      "aarch64-darwin" = "aarch64-apple-darwin";
      "x86_64-linux" = "x86_64-unknown-linux-musl";
    }
    .${prev.stdenv.hostPlatform.system};

  # nix-prefetch-url per platform; must be re-fetched on every codex version bump
  hostHashes = {
    "aarch64-apple-darwin" = "0im248hb4vb7wd0k4fkg87chszsac022ijy7d49m9zmy60j2iybc";
    "x86_64-unknown-linux-musl" = "0gcr30mf1mgfwqfpiqhmvjb0qyq23vwgfgjii7s2nz4lb9fcdn96";
  };

  # upstream package.nix omits the code-mode-host sidecar codex needs for all
  # tool calls since 0.144.0 (https://github.com/sadjow/codex-cli-nix/issues/121)
  codeModeHost = prev.fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${base.version}/codex-code-mode-host-${platform}.tar.gz";
    sha256 = hostHashes.${platform};
  };
in
{
  codex-cli = base.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      tar -xzf ${codeModeHost} -C $out/bin
      mv $out/bin/codex-code-mode-host-${platform} $out/bin/codex-code-mode-host
      chmod +x $out/bin/codex-code-mode-host
    '';
  });
}
