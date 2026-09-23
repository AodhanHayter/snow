{ ... }:
final: prev: {
  # pyscard's test suite fails on darwin (exit 133); skip it.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pfinal: pprev: {
      pyscard = pprev.pyscard.overridePythonAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    })
  ];
}
