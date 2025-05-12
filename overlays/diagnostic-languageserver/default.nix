
{ channels, ... }:
final: prev:
{
  inherit (channels.unstable) diagnostic-languageserver;
}
