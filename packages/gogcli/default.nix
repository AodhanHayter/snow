{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gogcli";
  version = "0.31.1";

  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "gogcli";
    rev = "v${version}";
    hash = "sha256-kTMxHPY3bv85X3H0TQGHLvL/nVVjh5fDF/S/z6Xd+bw=";
  };

  vendorHash = "sha256-fof2DVm6Cn1ZW7gKSYLHX6M6nPbtYBn6EKinptjhhrE=";

  # Tests require network access for OAuth flow
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/steipete/gogcli/internal/cmd.version=${version}"
  ];

  meta = {
    description = "CLI for Google Suite (Gmail, Calendar, Drive, Docs, Sheets, Contacts, Tasks)";
    homepage = "https://github.com/openclaw/gogcli";
    license = lib.licenses.mit;
    mainProgram = "gog";
  };
}
