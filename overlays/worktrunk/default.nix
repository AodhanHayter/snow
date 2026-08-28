{ channels, ... }:
final: prev: {
  worktrunk = channels.unstable.worktrunk.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      # Process-table probes are blocked by the darwin build sandbox.
      "--skip=shell::utils::tests::test_process_name_and_ppid_self"
      "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
      # Wall-clock timing assertions are flaky under a loaded build sandbox.
      "--skip=progress::imp::tests::test_progress_renders_after_startup_delay"
      "--skip=progress::imp::tests::test_watchdog_renders_after_startup_delay"
      "--skip=progress::imp::tests::test_watchdog_escalates_and_grows_the_block"
      "--skip=progress::imp::tests::test_watchdog_no_escalation_without_command"
    ];
  });
}
