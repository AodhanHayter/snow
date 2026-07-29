{ channels, ... }:
final: prev: {
  # Process-table probes are blocked by the darwin build sandbox.
  worktrunk = channels.unstable.worktrunk.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=shell::utils::tests::test_process_name_and_ppid_self"
      "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
    ];
  });
}
