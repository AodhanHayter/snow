{
  lib,
  stdenv,
  sox,
  ...
}:
stdenv.mkDerivation {
  pname = "arc-sounds";
  version = "1.0.0";

  dontUnpack = true;

  nativeBuildInputs = [ sox ];

  buildPhase = ''
    runHook preBuild

    RATE=44100
    BITS=16

    # ==========================================================
    # arc-alert.wav - Escalating detection beeps
    # Inspired by Arc Raiders Tick robots: rapid ascending tones
    # with metallic overdrive and low-frequency undertone
    # ==========================================================

    # Ascending sine tones (detection sequence)
    sox -n -r $RATE -b $BITS tone_600.wav  synth 0.07 sine 600  fade t 0.003 0.07 0.003
    sox -n -r $RATE -b $BITS tone_900.wav  synth 0.07 sine 900  fade t 0.003 0.07 0.003
    sox -n -r $RATE -b $BITS tone_1200.wav synth 0.07 sine 1200 fade t 0.003 0.07 0.003
    sox -n -r $RATE -b $BITS tone_1500.wav synth 0.07 sine 1500 fade t 0.003 0.07 0.003
    sox -n -r $RATE -b $BITS tone_2000.wav synth 0.10 sine 2000 fade t 0.003 0.10 0.003

    # Silence gaps between beeps
    sox -n -r $RATE -b $BITS gap_short.wav synth 0.035 sine 0

    # Concatenate beeps with gaps
    sox tone_600.wav gap_short.wav \
        tone_900.wav gap_short.wav \
        tone_1200.wav gap_short.wav \
        tone_1500.wav gap_short.wav \
        tone_2000.wav \
        alert_beeps.wav

    # Low 80Hz undertone for weight (total beep duration ~0.52s)
    sox -n -r $RATE -b $BITS undertone.wav synth 0.52 sine 80 fade t 0.01 0.52 0.05 gain -15

    # Mix beeps with undertone, apply metallic overdrive + reverb
    sox -m alert_beeps.wav undertone.wav alert_mixed.wav
    sox alert_mixed.wav arc-alert.wav overdrive 15 reverb 20 30 80 gain -3

    # ==========================================================
    # arc-complete.wav - Mechanical confirmation tone
    # Inspired by Arc Raiders power-down: descending tones
    # with slight reverb for a satisfying completion signal
    # ==========================================================

    sox -n -r $RATE -b $BITS comp_hi.wav  synth 0.10 sine 1200 fade t 0.005 0.10 0.005
    sox -n -r $RATE -b $BITS comp_mid.wav synth 0.10 sine 800  fade t 0.005 0.10 0.005
    sox -n -r $RATE -b $BITS comp_lo.wav  synth 0.18 sine 600  fade t 0.005 0.18 0.02
    sox -n -r $RATE -b $BITS gap_med.wav  synth 0.04  sine 0

    sox comp_hi.wav gap_med.wav comp_mid.wav gap_med.wav comp_lo.wav complete_raw.wav
    sox complete_raw.wav arc-complete.wav reverb 25 gain -3

    # ==========================================================
    # arc-scan.wav - Scanning/search sweep
    # Inspired by Arc Raiders Puncher scanning: frequency sweep
    # with tremolo and electronic character
    # ==========================================================

    sox -n -r $RATE -b $BITS arc-scan.wav \
        synth 0.5 sine 400:1600 \
        fade t 0.01 0.5 0.05 \
        tremolo 8 40 \
        reverb 30 \
        gain -3

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sounds/arc-raiders
    cp arc-alert.wav arc-complete.wav arc-scan.wav $out/share/sounds/arc-raiders/
    runHook postInstall
  '';

  meta = {
    description = "Arc Raiders-inspired robot alert sounds for Claude Code hooks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
