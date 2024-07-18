{ channels, ... }:
final: prev:
{
  inherit (channels.unstable) pulumi-bin;
}
