# Use packages from unstable which have cached binaries
# nixos-25.11's versions aren't cached due to build failures
{ inputs, ... }:
final: prev:
let
  unstablePkgs = import inputs.unstable {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  # LLVM - test failures on macOS 26
  llvmPackages_20 = unstablePkgs.llvmPackages_20;
  llvm_20 = unstablePkgs.llvm_20;

  # marksman/dotnet - version string bug in 25.11
  marksman = unstablePkgs.marksman;
  dotnetCorePackages = unstablePkgs.dotnetCorePackages;
}
