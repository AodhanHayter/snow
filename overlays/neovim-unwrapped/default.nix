{ channels, ... }:
final: prev: {
  neovim-unwrapped =
    (channels.unstable.neovim-unwrapped).overrideAttrs
      (oldAttrs: {
        # hack until unstable gets metadata fix
        meta = oldAttrs.meta // {
          maintainers = [ ];
        };
      });
}
