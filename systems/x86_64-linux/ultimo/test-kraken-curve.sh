#!/usr/bin/env bash
# No hardware writes. Optional argument tests the Nix-built executable instead.
set -euo pipefail
script=${1:-$(dirname "$0")/kraken-curve.sh}
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
printf 'z53\n' > "$fixture/name"
for channel in 1 2; do
  printf '5\n' > "$fixture/pwm${channel}_enable"
  for point in {1..40}; do
    printf '0\n' > "$fixture/temp${channel}_auto_point${point}_pwm"
  done
done

bash "$script" "$fixture"
for channel in 1 2; do
  [[ $(<"$fixture/pwm${channel}_enable") == 2 ]]
  previous=0
  for point in {1..40}; do
    duty=$(<"$fixture/temp${channel}_auto_point${point}_pwm")
    ((duty >= previous && duty <= 255))
    previous=$duty
  done
  [[ $previous == 255 ]]
done
[[ $(<"$fixture/temp1_auto_point1_pwm") == 178 ]]  # 70% pump floor
[[ $(<"$fixture/temp1_auto_point11_pwm") == 178 ]] # 30°C
[[ $(<"$fixture/temp1_auto_point16_pwm") == 216 ]] # 35°C: 85%
[[ $(<"$fixture/temp1_auto_point21_pwm") == 255 ]] # 40°C: 100%
[[ $(<"$fixture/temp2_auto_point1_pwm") == 89 ]]   # 35% fan floor
[[ $(<"$fixture/temp2_auto_point11_pwm") == 89 ]]  # 30°C
[[ $(<"$fixture/temp2_auto_point16_pwm") == 142 ]] # 35°C: 56%
[[ $(<"$fixture/temp2_auto_point26_pwm") == 255 ]] # 45°C: 100%
[[ ! -e "$fixture/temp1_auto_point41_pwm" ]]
[[ ! -e "$fixture/temp2_auto_point41_pwm" ]]

# Reapplication also succeeds. Unsupported devices/interfaces change nothing.
bash "$script" "$fixture"
printf 'other\n' > "$fixture/name"
if bash "$script" "$fixture"; then
  echo 'Wrong device accepted' >&2
  exit 1
fi
printf 'z53\n' > "$fixture/name"
rm "$fixture/temp2_auto_point40_pwm"
if bash "$script" "$fixture"; then
  echo 'Incomplete interface accepted' >&2
  exit 1
fi
[[ $(<"$fixture/pwm1_enable") == 2 ]]
[[ $(<"$fixture/pwm2_enable") == 2 ]]

# A write failure while staging must leave BOTH channels at full speed.
ln -s /dev/full "$fixture/temp2_auto_point40_pwm"
if bash "$script" "$fixture" 2>/dev/null; then
  echo 'Failed write accepted' >&2
  exit 1
fi
[[ $(<"$fixture/pwm1_enable") == 0 ]]
[[ $(<"$fixture/pwm2_enable") == 0 ]]
echo 'Kraken curve checks passed (no hardware accessed).'
