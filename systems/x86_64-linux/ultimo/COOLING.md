# Cooling on ultimo

The Kraken Z53 controls its pump and radiator fans from coolant temperature.
[kraken-curve.sh](kraken-curve.sh) defines these starting values:

| Channel | Minimum through 30°C | Full speed at |
| --- | --- | --- |
| Pump | 70% | 40°C coolant |
| Radiator fans | 35% | 45°C coolant |

Speed increases linearly between these temperatures. Neither channel stops.
These are conservative starting values, not a measured acoustic optimum.
Test sustained CPU and GPU workloads before reducing the minimum speeds.

[cooling.nix](cooling.nix) applies the curves when the kernel exposes the cooler.
The cooler then runs them without a polling daemon. USB device removal stops
that service instance. Reconnection starts another instance and reapplies the curves.
Stopping the service does not restore the old curve or stop cooling.
Suspend remains disabled in this host's configuration.

The service briefly sets both channels to full speed before it writes the curves.
A failed write before activation leaves full speed on channels not yet activated.
A channel already activated retains its complete curve.
The service retries failures, with at most three starts per minute.
It waits for the existing OpenRGB startup service to finish.
The Linux 6.18 interface has 40 write-only curve points, for 20–59°C.
The script uses this interface directly rather than adding liquidctl as a dependency.
Do not run another fan controller against the Kraken at the same time.

The `nct6775` module exposes the N7 B550's NCT6798D sensors.
Its fan headers retain their existing firmware Smart Fan IV control.
Physical wiring remains unconfirmed, so no motherboard channel is reassigned
or given a new curve. The NVIDIA GPU retains its automatic fan control.

## Apply and inspect

Run these commands from the repository root on `ultimo`. The rebuild activates
all changes in the host configuration, not only the cooling changes.
The targeted udev event starts the service without a reboot.
After editing a curve, explicitly restart the existing instance.

```sh
doas nixos-rebuild switch --flake .#ultimo
doas udevadm trigger --action=add --subsystem-match=hwmon --attr-match=name=z53
doas udevadm settle
doas systemctl restart 'kraken-cooling@*'
systemctl status 'kraken-cooling@*' --no-pager
sensors
```

The service must show `active (exited)`. Both Kraken `pwm*_enable` values must be `2`:

```sh
for h in /sys/class/hwmon/hwmon*; do
  if [ "$(cat "$h/name")" = z53 ]; then
    cat "$h/pwm1_enable" "$h/pwm2_enable"
  fi
done
```

Use `watch -n 2 sensors` during a representative workload. Watch coolant temperature,
CPU temperature, pump speed, and radiator fan speed. Stop the workload if coolant
reaches 50°C, the CPU stays at its 90°C limit, or either Kraken speed becomes zero.
These are conservative test-stop conditions, not software shutdown thresholds.
No temperature-alert or automatic shutdown service is configured.

Some DIMM and motherboard readings report alarms against unconfigured zero limits.
Unused auxiliary temperature inputs can also report implausible values.
Those flags alone do not establish overheating. Do not change limits or assign
sensor labels without confirming the board's wiring.

## Test and recover

The local test uses temporary files and never accesses hardware:

```sh
bash systems/x86_64-linux/ultimo/test-kraken-curve.sh
```

To request full speed immediately, run the following on `ultimo`.
On this specific driver, mode `0` means full speed, not fan stop.
This replaces the active curves until the service restarts or the device resets.

```sh
for h in /sys/class/hwmon/hwmon*; do
  if [ "$(cat "$h/name")" = z53 ]; then
    printf '0\n' | doas tee "$h/pwm1_enable" "$h/pwm2_enable" >/dev/null
  fi
done
```

Removing the configuration or stopping its service does not undo an onboard curve.
Use full speed first if you remove this configuration. Reapply known-good curves
before returning to normal operation.

Sources: [Linux Kraken driver](https://docs.kernel.org/hwmon/nzxt-kraken3.html),
[systemd device activation](https://www.freedesktop.org/software/systemd/man/latest/systemd.device.html).
