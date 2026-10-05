#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Kraken curve setup failed at line $LINENO: $BASH_COMMAND" >&2' ERR

hwmon=${1:?Expected the Kraken hwmon directory}
[[ $(<"$hwmon/name") == z53 ]]
# Validate the whole interface before changing either channel.
for channel in 1 2; do
  [[ -w "$hwmon/pwm${channel}_enable" ]]
  for point in {1..40}; do
    [[ -w "$hwmon/temp${channel}_auto_point${point}_pwm" ]]
  done
done

# Mode 0 means FULL SPEED on nzxt_kraken3, not fan stop. Stage curves in
# this mode: writing points in mode 2 floods the cooler with USB reports.
printf '0\n' > "$hwmon/pwm1_enable"
sleep 0.2
printf '0\n' > "$hwmon/pwm2_enable"

set_curve() {
  local channel=$1 minimum=$2 start=$3 full=$4 temp duty
  for ((temp = 20; temp < 60; temp++)); do
    duty=$((minimum + (100 - minimum) * (temp - start) / (full - start)))
    ((duty >= minimum)) || duty=$minimum
    ((duty <= 100)) || duty=100
    printf '%s\n' "$((duty * 255 / 100))" \
      > "$hwmon/temp${channel}_auto_point$((temp - 19))_pwm"
  done
}

# Channel, minimum duty (%), ramp start (coolant °C), full speed (coolant °C).
set_curve 1 70 30 40 # Pump: never stop it.
set_curve 2 35 30 45 # Radiator fans: no uncalibrated fan-stop mode.

# Commit only after both complete curves are staged. Earlier failures leave
# full speed; the cooler runs these curves without a userspace polling loop.
sleep 0.2
printf '2\n' > "$hwmon/pwm1_enable"
sleep 0.2
printf '2\n' > "$hwmon/pwm2_enable"
