# Performance on ultimo

The largest confirmed limit is the slot that holds the Linux SSD.
Move that drive to the faster slot before trying software changes for storage throughput.
This requires physical access and a shutdown, not a Nix configuration change.

## Observed baseline

Read-only inspection over SSH on 2026-10-27 found the following state.
The host ran Linux 6.18.55 and NVIDIA driver 595.71.05.
No throughput benchmarks, stress tests, firmware changes, or rebuilds ran during this inspection.

| Component | Observation |
| --- | --- |
| Motherboard | NZXT N7 B550, BIOS P1.50 dated 2021-08-04 |
| CPU | Ryzen 9 5900X, 12 cores / 24 threads, boost and preferred-core selection enabled |
| CPU frequency control | `amd-pstate-epp`, active mode, `powersave`, energy preference `balance_performance` on all 24 threads |
| Memory | 64 GiB, four 16 GiB modules, firmware reports 3600 MT/s |
| Linux SSD | Samsung 980 PRO 2 TB, `nvme0n1`, PCI address `04:00.0`, PCIe 3.0 ×2 |
| Other NVMe SSD | Samsung 980 PRO 2 TB, `nvme1n1`, PCI address `01:00.0`, PCIe 4.0 ×4, unmounted NTFS partitions |
| NVMe health | Both report firmware `5B2QGXA7`, 100% spare capacity, zero media errors, zero critical warnings |
| NVMe wear | Linux drive reports 1% used endurance, other drive reports 0% |
| SATA SSDs | Two Samsung 870 EVO 1 TB drives, both pass health checks with zero reported reallocated sectors or interface errors |
| Root filesystem | ext4, `relatime`, 40% used, NVMe scheduler `none` |
| TRIM | Weekly timer active, last run succeeded on October 26 and took 10 minutes 51 seconds |
| GPU | RTX 3070 Ti 8 GB, open kernel driver, 16 PCIe lanes, 8 GB resizable memory window |
| GPU power | Default 290 W limit, approximately 18 W and 30°C at idle |
| Cooling | CPU approximately 43°C, coolant approximately 26°C, NVMe drives approximately 36–48°C at light load |

SMART is the drive's built-in health reporting system. Passing SMART does not replace backups or prove maximum throughput.
The GPU reported no accumulated thermal slowdown, but sustained load behavior remains untested.
The long TRIM run warrants latency measurements during a future run, not an assumption that it causes slow applications.

## Fix the SSD slot limit

The [N7 B550 specifications](https://support.nzxt.com/hc/en-us/articles/37547153004827-N7-B550-Specs) define these limits for the 5900X:

| Slot | Connection | Current use inferred from PCI topology |
| --- | --- | --- |
| `M2_1` | CPU-connected PCIe 4.0 ×4 | Drive with NTFS partitions |
| `M2_2` | Chipset-connected PCIe 3.0 ×2 | Linux root, EFI boot partition, and swap |

The kernel also reports the Linux drive's link limit at bridge `03:04.0`.
These connections have theoretical bandwidths of about 7.88 GB/s and 1.97 GB/s before protocol overhead.
That is a fourfold link difference, not a promise that applications will run four times faster.
A kernel parameter cannot add lanes to `M2_2`.

If Linux performance takes priority, exchange the drives between these slots during a maintenance window.
Back up both drives first. Record their physical identities and boot entries before shutdown.
The NTFS drive will then inherit the slower connection.

The repository mounts Linux filesystems and swap by UUID, so their configuration does not depend on NVMe numbering.
Device names can change after the move. Firmware boot entries can still need repair, so have a local recovery USB available.
Do not repartition, format, or copy raw disks for this slot exchange.
Afterward, make sure that Linux boots and its drive reports `16.0 GT/s PCIe` with width `4`.

## Keep CPU and GPU policies conservative

With the [AMD active-mode driver](https://docs.kernel.org/6.18/admin-guide/pm/amd-pstate.html), `powersave` does not mean a fixed low clock.
The current energy preference balances performance and power, and boost remains enabled.
There is no observed CPU frequency cap that requires a workaround.

Two corrected CPU machine-check events appeared on October 16 and 18.
A machine check is a hardware error report. The decoder reported reserved banks 26 and 24, so the faulty component is not established.
Do not infer a failed CPU or bad RAM from those messages alone.

The [NZXT downloads page](https://support.nzxt.com/hc/en-us/articles/39555142239003-N7-B550-Downloads) lists BIOS 3.90 and intervening firmware fixes.
Review the [vendor update procedure](https://support.nzxt.com/hc/en-us/articles/11652846587803-Updating-your-NZXT-Motherboard-BIOS) with physical access before an update.
Save firmware settings and any encrypted-OS recovery keys first.
An update can reset memory, boot, and security settings. It is not a proven fix for these error reports.
If errors recur, test stock CPU and memory settings before considering overclocking or undervolting.

The GPU already exposes its full memory window and all 16 lanes.
Its idle PCIe speed is 2.5 GT/s. That observation alone does not establish a link problem under load.
Hyprland and Sunshine already hold GPU contexts open.
[NVIDIA persistence](https://docs.nvidia.com/deploy/driver-persistence/overview.html) addresses initialization between clients, not sustained GPU throughput.
No persistence daemon, locked clocks, or increased power limit is added.

After the stability checks, compare the same representative build or application workload before and after each candidate change.
A CPU candidate is `powerManagement.cpuFreqGovernor = "performance";` in this host's configuration.
The pinned NixOS module applies that option independently of `powerManagement.enable`.
It prioritizes performance over energy savings, so measure elapsed time, temperatures, and power before retaining it.
No gain from that candidate is established here.
Use the [cooling guide](COOLING.md) for monitoring and test-stop conditions.

## Declarative changes

[default.nix](default.nix) retains weekly TRIM and adds the following:

- `services.smartd.enable`: Monitor all detected drives with the default health checks, without scheduled self-tests.
- `hardware.rasdaemon.enable`: Record future supported hardware-error events in `/var/lib/rasdaemon`.
- `dmidecode`, `nvme-cli`, `pciutils`, and `smartmontools`: Keep inspection tools available after a rebuild.

The rasdaemon module also installs `ras-mc-ctl` and enables database recording by default.
It does not import historical journal events or guarantee that every hardware fault is detectable.
SMART warnings go to the journal and logged-in terminals. No email or external alert destination is configured.
These changes improve diagnosis, not measured throughput.
CPU policy, GPU policy, mount options, NVMe power saving, security mitigations, and cooling curves remain unchanged.

## Apply and inspect

Targeted Nix assertions, formatting, Markdown validation, and fish syntax checks passed for this change.
Full-host evaluation failed on an undefined Home Manager file source for `com.github.browserpass.native.json` under a macOS Chrome path.
The same error reproduced at unchanged commit `87c517f`. Resolve that separate blocker before attempting a rebuild.

Review the full host diff before deployment. A rebuild activates all pending host changes, not only these additions.
From the repository root on `ultimo`, after synchronizing the reviewed commit, apply it explicitly:

```fish
doas nixos-rebuild switch --flake .#ultimo
systemctl is-active smartd rasdaemon
journalctl -u smartd -u rasdaemon -b --no-pager
doas ras-mc-ctl --summary
```

Both services must report `active`. Make sure that the SMART startup log lists all four drives.
These activation checks were not run during the inspection.
If activation causes a problem, select the previous system generation or run `doas nixos-rebuild switch --rollback`.
Rollback affects the whole generation, not just these services.

Run these read-only commands on `ultimo` to inspect storage and its connection:

```fish
lsblk -o NAME,MODEL,SIZE,FSTYPE,MOUNTPOINTS
findmnt -no SOURCE,FSTYPE,OPTIONS /
systemctl list-timers fstrim.timer --no-pager
for controller in /sys/class/nvme/nvme*
    grep -H . $controller/model $controller/firmware_rev $controller/device/current_link_speed $controller/device/current_link_width
end
```

After identifying the current Linux drive, use `doas smartctl -a /dev/nvme0` for its health report.
Replace `/dev/nvme0` if numbering changed. Do not assume that the original name still identifies Linux after moving drives.
Use `doas dmidecode -t memory` to inspect the memory speed reported by firmware.

Run these read-only commands to inspect CPU policy and GPU state:

```fish
grep -H . /sys/devices/system/cpu/amd_pstate/status /sys/devices/system/cpu/cpufreq/boost
grep -H . /sys/devices/system/cpu/cpufreq/policy*/scaling_governor /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference
nvidia-smi -q -d PERFORMANCE,POWER,TEMPERATURE,CLOCK
sensors
```

Measure the actual build, compute job, or remote-desktop workload before claiming an improvement.
No synthetic write benchmark or stress test is configured to run automatically.
