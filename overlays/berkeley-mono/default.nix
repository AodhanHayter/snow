{ inputs, ... }:
final: prev: {
  berkeley-mono = prev.stdenvNoCC.mkDerivation {
    pname = "berkeley-mono";
    version = "2026.04.13";

    src = "${inputs.berkeley-mono}/fonts";

    installPhase = ''
      runHook preInstall
      install -D -m444 -t $out/share/fonts/opentype *.otf
      runHook postInstall
    '';

    meta = {
      description = "Berkeley Mono typeface";
      homepage = "https://berkeleygraphics.com/typefaces/berkeley-mono/";
      license = prev.lib.licenses.unfree;
    };
  };
}
