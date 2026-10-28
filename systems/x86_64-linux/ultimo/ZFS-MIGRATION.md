# ZFS migration plan for ultimo

Status: planned, not implemented. This document records the agreed direction and the decisions still open.
It does not authorize erasing disks. No ZFS installation, replication, or Garage service exists from this plan yet.
Destructive commands are intentionally omitted until disk identities and permissions are settled.
The migration procedure is not yet rehearsed. No throughput or restore tests ran during planning.

The goal is to install NixOS on the faster NVMe drive and retain local recovery copies on the slower drive.
The SATA pair is a possible development object store, not a requirement for the operating-system migration.
No physical exchange of the NVMe drives is needed for this approach.

## Decisions and open questions

| Topic | Direction | Status |
| --- | --- | --- |
| Active system | Single-drive ZFS pool on the PCIe 4.0 ×4 NVMe | Agreed direction |
| Local recovery | Scheduled snapshot replication to the PCIe 3.0 ×2 NVMe | Agreed direction, after the new installation passes acceptance |
| SATA drives | Approximately 1 TB usable ZFS mirror backing a separate Garage instance | Proposed optional follow-up |
| NTFS contents | Erase the fast NVMe for installation | Explicit permission still required |
| Existing NixOS | Preserve the slow NVMe until the replacement works | Required migration safeguard |
| Encryption | Choose encrypted or unencrypted storage and a boot-unlock method | Undecided |
| Swap | Choose compressed RAM swap or a separate disk partition | Undecided, no ZFS swapfile or swap volume |
| Replication policy | Select datasets, frequency, retention, and capacity limits | Undecided |
| Garage compatibility | Establish whether applications need versioning, notifications, or object locking | Undecided |

Encryption affects unattended reboots. Passphrase unlocking needs an operator, while automatic unlocking needs a separate security design.
Keep recovery keys outside the machine and outside Git. Do not assume that the existing SOPS key can unlock an encrypted root filesystem.

## Starting point

The October 27, 2026 inspection found these drives. Device names are historical observations, not safe installation selectors.
The [performance report](PERFORMANCE.md) contains the hardware evidence and health readings.
Both SATA drives lacked recognized filesystem signatures, but that does not establish permission to erase them.

| Observed device | Hardware | Connection | Existing contents | Intended use |
| --- | --- | --- | --- | --- |
| `nvme1n1` | Samsung 980 PRO, 2 TB | `M2_1`, PCI address `01:00.0`, PCIe 4.0 ×4 | Unmounted NTFS partitions | New NixOS pool |
| `nvme0n1` | Samsung 980 PRO, 2 TB | `M2_2`, PCI address `04:00.0`, PCIe 3.0 ×2 | ext4 root, EFI boot partition, swap | Temporary fallback, then replica pool |
| `sda` | Samsung 870 EVO, 1 TB | SATA | No recognized partition/filesystem signature | Optional Garage mirror member |
| `sdb` | Samsung 870 EVO, 1 TB | SATA | No recognized partition/filesystem signature | Optional Garage mirror member |

Before installation, record each drive's serial number and whole-disk `/dev/disk/by-id/` path.
Match these against capacity, partitions, mountpoints, and the NVMe connection. Do not choose between identical models by model name alone.
Repeat this identification from the installer because device numbering can change.

The host has a Ryzen 9 5900X, 64 GiB RAM, and an RTX 3070 Ti.
Two corrected CPU hardware-error reports appeared during the inspected boot. Their cause remains unknown.
Reassess stability before migration, and keep any BIOS update separate from the filesystem change.

## Proposed storage layout

A pool groups physical storage. A dataset is a filesystem with independent storage policies.
A snapshot preserves an earlier dataset state. Replication copies snapshots into another pool.
The following names and dataset boundaries are proposals for implementation, not existing resources.

```text
Fast NVMe, 2 TB
├── Dedicated FAT32 EFI partition mounted at /boot/efi
├── Optional separate swap partition
└── rpool: single-drive ZFS pool
    ├── rpool/root   → /
    ├── rpool/nix    → /nix
    ├── rpool/home   → /home
    └── rpool/state  → /var/lib

Slower NVMe, 2 TB, only after acceptance
└── replica: single-drive ZFS pool
    └── Selected snapshots received from rpool, not mounted over live paths

Two SATA SSDs, 1 TB each, optional later phase
└── objects: ZFS mirror, approximately 1 TB usable
    └── objects/garage → /var/lib/garage
```

Actual capacity is lower after boot partitions, filesystem overhead, and reserved free space.
The root pool has no disk redundancy. Its failure requires recovery, even when the replica is healthy.
The replica is not a bootable copy, and scheduled replication can lose changes since the last successful transfer.

Start with LZ4 compression, checksums enabled, and normal synchronous-write guarantees.
Keep deduplication disabled. Do not add cache devices, log devices, or arbitrary memory limits without measurements.
Confirm the drives' sector geometry before selecting the pool's sector-size configuration.

Use snapshots for meaningful home and application state, not long retention of reproducible build caches.
Separate disposable container/build data further only if retention requirements justify another dataset.
A filesystem snapshot is not automatically a consistent database backup. Quiesce applications or use their supported backup procedures.

## Repository changes to prepare

The `snow` repository continues to own ultimo's operating system.
The sibling `../kin` repository describes the cluster, not ultimo's installation target.
Do not introduce a second full-machine configuration owner as part of this migration.

The future implementation needs these changes:

- Add a host-local Disko layout for the fast NVMe, selected by its stable whole-disk ID. Disko is already imported by `flake.nix`.
- Replace the old root, EFI, and swap definitions in [hardware.nix](hardware.nix). Preserve its other hardware configuration.
- Import the new layout from [default.nix](default.nix). Keep `system.stateVersion = "22.05"` unless a separate compatibility review requires otherwise.
- Retain systemd-boot and `/boot/efi`. Provide a new EFI partition on the fast drive, initially sized at 1 GiB.
- Configure ZFS boot support and a stable `networking.hostId`. Make sure that required datasets, including `/nix`, are available during boot.
- Select a supported kernel/ZFS/NVIDIA combination. Build the full system and test an installer that can import the new pools.
- Declare snapshot retention and replication through the existing NixOS Sanoid and Syncoid services.
- Declare periodic ZFS integrity scans and SSD TRIM. Do not assume that `services.fstrim` maintains ZFS pools.
- Retain SMART monitoring, hardware-error recording, and the existing cooling configuration.

Provision each phase through a separately reviewed disk target set.
The initial installer must contain only the fast NVMe as a destructive target.
Never rerun an all-disks formatting operation to add the replica or SATA pool.

Build the prospective configuration without activating it on the current ext4 installation.
Do not run `nixos-rebuild switch` merely to prepare the new root layout.
The installation and later pool-creation procedures need their own explicit approval.

## Phase 1: Prepare without changing disks

Do not start installation until the full system builds and recovery material is available outside all four target disks.
The earlier full-host evaluation failed on an undefined browserpass Home Manager file source under a macOS Chrome path.
That error also reproduced at commit `87c517f`, before the monitoring changes. Recheck and resolve it before migration.

1. Record and approve the exact fast-drive ID and the loss of its NTFS contents.
2. Decide encryption, unlocking, swap, and the initial dataset boundaries.
3. Preserve unpushed work, SSH/GPG keys, application state, and anything inconvenient to recreate.
4. Preserve `/home/aodhan/.config/sops/age/keys.txt` securely outside the machine.
5. Record how to recover SSH host identity, Tailscale access, Sunshine pairing, and runner registrations.
6. Save the current configuration commit and the original firmware boot entries.
7. Build the new system on an x86_64-linux host, without switching the running system.
8. Prepare a compatible NixOS installer USB and local console access.
9. Arrange access to private flake inputs, including `berkeley-mono`, without committing credentials or copying them into the Nix store.
10. Record representative build and application timings before migration, if performance comparison is wanted.

Restore the age key into the target system before activation needs it. Configuration alone cannot recreate secret key material.
If root encryption is selected, arrange its unlock credentials independently of secrets stored on that encrypted root.
Use the [cooling guide](COOLING.md) when measuring sustained workloads.

Exit condition: the full build succeeds, disk identity is unambiguous, and credentials can be recovered without either NVMe drive.
There is no permission yet to erase the old NixOS installation or either SATA drive.
A changed SSH host key requires independent verification, not disabling host-key checks.

## Phase 2: Install on the fast NVMe only

This phase destroys the fast drive's existing partitions. Obtain explicit approval immediately before formatting.
Keep the old NixOS drive and both SATA drives outside the formatting target set.
Pause runner jobs and other writes before shutdown so the old installation remains a clean fallback.

1. Boot the installer in UEFI mode and establish authenticated SSH access.
2. Match the approved drive ID against the installer's inventory and the PCIe 4.0 ×4 connection.
3. Inspect the resolved Disko target list and make sure that it contains only that drive.
4. Create the new boot partition and root pool using the reviewed procedure.
5. Restore required credentials into the mounted target with their original ownership and restrictive permissions.
6. Install this repository's `nixosConfigurations.ultimo` onto the mounted target filesystems.
7. Install systemd-boot onto the new drive's EFI partition, not the old drive's partition.
8. Select the new drive's firmware boot entry and boot NixOS.

Exit condition: the new system boots from the fast NVMe while the old NixOS drive remains unchanged.
Do not enable replication against the old drive yet. It still contains the fallback installation.
If installation fails, use the original firmware boot entry or the recovery USB.

## Phase 3: Accept the new installation

Keep the old installation through a normal work cycle and a successful reboot of the replacement.
If practical, test booting with the old NVMe temporarily disconnected. That proves the new system does not depend on its EFI partition.
The acceptance evidence must cover these points:

- Root belongs to `rpool`, and the active EFI partition belongs to the fast drive.
- The root drive reports `16.0 GT/s PCIe` and link width `4`.
- ZFS reports a healthy pool without read, write, or checksum errors.
- SSH, DNS, networking, Tailscale, and SOPS decryption work after reboot.
- Hyprland, NVIDIA acceleration, and Sunshine work with the selected kernel.
- Podman and the separate NixOS containers for GitHub runners work on the new filesystem layout.
- Cooling and health-monitoring services run without new unexplained hardware errors.
- A representative build completes correctly, with acceptable elapsed time and temperatures.
- A file can be recovered from a test snapshot without rolling back the live root filesystem.

Comparing old ext4 on the slow connection with new ZFS on the fast connection measures both changes together.
It cannot isolate the filesystem's performance cost. No fourfold application speedup is assumed.

Exit condition: acceptance evidence is recorded and the user approves retiring the old installation.
Before erasing it, make sure that all required old files and all newly created work have recoverable copies.
Do not use the old drive as the only copy of any migration credential.

## Phase 4: Convert the old NVMe into the replica

This phase destroys the old NixOS installation and ends the immediate boot fallback.
Obtain separate approval for the old drive's stable ID. Use a provisioning operation that cannot format `rpool` or either SATA drive.
Keep the accepted installation commit and an external recovery copy of essential files before proceeding.

1. Create the independent `replica` pool on the old NVMe.
2. Select the datasets to copy and set retention for both source and destination.
3. Configure scheduled snapshots with Sanoid and replication with Syncoid.
4. Keep received datasets unmounted and prevent their mount properties from shadowing live paths such as `/` or `/home`.
5. Run an initial transfer, then an incremental transfer after changing a test file.
6. Restore that file into a temporary location and compare its contents.
7. Establish checks for failed transfers, stale replicas, pool health, and low free space.

A possible starting policy is hourly replication of home and selected application state.
Proposed retention is 24 hourly, 7 daily, and 4 weekly snapshots, subject to the actual change rate and free space.
Finalize these values before enabling schedules. Budget source and replica space separately, even though both drives have the same nominal capacity.

The EFI partition is outside ZFS and is not included in these transfers.
Recovery therefore includes reinstalling the bootloader and reconstructing the system from its pinned configuration.
Do not upgrade pool features casually while relying on older installers for recovery.

## Phase 5: Optional development object store

The proposed service is a separate Garage instance on ultimo, backed by a SATA ZFS mirror.
It does not join lenny's Garage deployment and does not require ultimo to become a k3s node.
The `rpool/state` snapshots do not include the separately mounted Garage dataset. Its backup policy is independent.
Confirm that this use is wanted before erasing either SATA drive.

The implementation proposal is:

- Create the `objects` mirror using both approved SATA drive IDs.
- Keep Garage data and metadata together under `objects/garage`, mounted at `/var/lib/garage`.
- Run Garage as a host-managed NixOS service with Garage replication factor 1. ZFS provides the two-disk mirror beneath it.
- Require the dataset mount before Garage starts, so a missing pool cannot redirect writes into the root filesystem.
- Provision separate development buckets and access keys through SOPS-backed configuration. Do not reuse the cluster's backup credentials.
- Restrict access to approved LAN or Tailscale clients, with an explicit transport-security decision and no public exposure by default.
- Set a capacity limit that leaves pool headroom and decide whether development objects need an external backup.

Garage supports ordinary object operations, multipart uploads, and presigned URLs.
Its current compatibility table excludes bucket versioning, event notifications, and object locking.
Confirm the application's API requirements before choosing it as an S3 development substitute.

As checked during planning, the MinIO community repository is archived and marked unmaintained.
Do not silently substitute an old MinIO deployment. Reassess maintained alternatives if Garage lacks a required API.

Acceptance requires upload/download, multipart, presigned-URL, permission-isolation, and reboot-persistence tests from the actual development client.
Use a Garage-supported backup procedure or quiesce the service before a coordinated snapshot of its data and metadata.
Test restoration before treating those snapshots as usable backups.

## Cluster boundary

Use `../kin` for cluster planning, not the historical k3s files in this repository.
The reviewed `kin` revision was `ec01979`. Its README was also stale, so the service modules supplied the relevant facts.
Live cluster verification was blocked by an SSH host-key mismatch and was not completed.

That configuration declares Longhorn 1.12 with three replicas by default and a separate single-replica class for CloudNativePG.
It also declares a single-copy Garage store on lenny's 1 TB HDD.
None of those resources changes as part of this plan.

Contributing ultimo's SATA drives to Longhorn remains an alternative, not part of the proposed Garage mirror.
That alternative needs a worker-node design and independently mounted filesystems suited to Longhorn, rather than an assumed ZFS mirror underneath it.
Do not allocate the same disks to both purposes.

## Recovery and completion

| Failure point | Recovery path | Limitation |
| --- | --- | --- |
| New installation fails before old NVMe reuse | Boot the old installation through firmware or the recovery USB | Save new work before switching back |
| New configuration breaks after acceptance | Select a working NixOS generation, if its kernel supports the pool | Generations do not restore application data |
| Fast NVMe fails after replica provisioning | Replace the drive, recreate its layout, reinstall, and restore selected snapshots | Downtime and changes since the last replication remain |
| One SATA mirror member fails | Replace it and rebuild the missing mirror copy | Still only one host and one object-store instance |
| Accidental object deletion or application corruption | Restore a retained, tested backup | Mirroring also mirrors deletions |

A ZFS snapshot rollback is not a complete machine rollback. Boot files, dataset consistency, and application state need separate consideration.
Do not roll back live root or database datasets as an unreviewed recovery shortcut.
An independent replica and a mirror in the same chassis do not protect against theft, host-wide compromise, or destruction of the machine.

The migration is complete only when the new system passes acceptance and the replica restores a test file successfully.
The optional object-store phase has its own approval and acceptance gates.
Keep an off-machine copy of irreplaceable files and record the final layout, schedules, credentials procedure, and recovery evidence here after implementation.

## References

- [Hardware findings and existing performance limits](PERFORMANCE.md)
- [Cooling and workload test-stop conditions](COOLING.md)
- [NixOS ZFS guide](https://wiki.nixos.org/wiki/ZFS)
- [Disko installation guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md)
- [Sanoid and Syncoid](https://github.com/jimsalterjrs/sanoid)
- [OpenZFS workload tuning](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html)
- [Garage S3 compatibility](https://garagehq.deuxfleurs.fr/documentation/reference-manual/s3-compatibility/)
- [MinIO community repository status](https://github.com/minio/minio)
