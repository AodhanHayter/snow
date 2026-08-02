{ channels, ... }:
final: prev: {
  # Obsidian CLI requires >= 1.12; stable channel only has 1.10.x
  inherit (channels.unstable) obsidian;
}
