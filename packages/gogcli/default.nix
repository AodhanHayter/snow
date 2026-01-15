{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gogcli";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "steipete";
    repo = "gogcli";
    rev = "v${version}";
    hash = "sha256-DynVRDrqV0Zs2dvTDPbQryXw3gaYIyC9xjFWhEyPcOI=";
  };

  vendorHash = "sha256-tS73R7tg/YOBQGjkY+mn2MpzFHVedPC8iXFHTbhMRBQ=";

  # Tests require network access for OAuth flow
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/steipete/gogcli/internal/cmd.version=${version}"
  ];

  meta = {
    description = "CLI for Google Suite (Gmail, Calendar, Drive, Docs, Sheets, Contacts, Tasks)";
    homepage = "https://github.com/steipete/gogcli";
    license = lib.licenses.mit;
    mainProgram = "gog";
  };
}
