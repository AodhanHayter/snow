{ inputs, ... }:
final: prev:
let
  claude-code-bun = inputs.claude-code-nix.packages.${prev.stdenv.hostPlatform.system}.claude-code-bun;
in
{
  claude-code = prev.symlinkJoin {
    name = "claude-code";
    paths = [ claude-code-bun ];
    postBuild = ''
      rm $out/bin/claude-bun
      ln -s ${claude-code-bun}/bin/claude-bun $out/bin/claude
    '';
  };
}
