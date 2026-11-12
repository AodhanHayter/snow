{ ... }:
final: prev: {
  # test_read_text_file reads real /nix/store (unsandboxed on darwin); fails if picked file contains "Error"
  mcp-nixos = prev.mcp-nixos.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_read_text_file" ];
  });
}
