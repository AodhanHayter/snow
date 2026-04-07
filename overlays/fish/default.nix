{ ... }:
final: prev: {
  fish = prev.fish.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
        for f in $out/bin/*; do
          if [ -f "$f" ] && [ -x "$f" ] && file "$f" | grep -q "Mach-O"; then
            /usr/bin/codesign --force --sign - "$f"
          fi
        done
      fi
    '';
  });
}
