{ stdenv
, lib
, buildGoModule
, fetchFromGitHub
, pcsclite
, pkg-config
, installShellFiles
, PCSC
, pivKeySupport ? true
, pkcs11Support ? true
, testers
, cosign
}:
buildGoModule rec {
  pname = "cosign";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "sigstore";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-x03I86WJT+dLToeGzIaPrLJK0G7siVZuJHjE1WjZao0=";
  };

  buildInputs =
    lib.optional (stdenv.isLinux && pivKeySupport) (lib.getDev pcsclite)
    ++ lib.optionals (stdenv.isDarwin && pivKeySupport) [ PCSC ];

  nativeBuildInputs = [ pkg-config installShellFiles ];

  vendorHash = "sha256-eTyFIuq9G9/0t5ePZNsBpKJ/lcUU0ryqzg6i+nqbHc4=";

  subPackages = [
    "cmd/cosign"
  ];

  tags = [ ] ++ lib.optionals pivKeySupport [ "pivkey" ] ++ lib.optionals pkcs11Support [ "pkcs11key" ];

  ldflags = [
    "-s"
    "-w"
    "-X sigs.k8s.io/release-utils/version.gitVersion=v${version}"
    "-X sigs.k8s.io/release-utils/version.gitTreeState=clean"
  ];

  __darwinAllowLocalNetworking = true;

  preCheck = ''
    # test all paths
    unset subPackages

    rm pkg/cosign/ctlog_test.go # Require network access
    rm pkg/cosign/tlog_test.go # Require network access
    rm cmd/cosign/cli/verify/verify_blob_attestation_test.go # Require network access
  '';

  postInstall = ''
    installShellCompletion --cmd cosign \
      --bash <($out/bin/cosign completion bash) \
      --fish <($out/bin/cosign completion fish) \
      --zsh <($out/bin/cosign completion zsh)
  '';

  passthru.tests.version = testers.testVersion {
    package = cosign;
    command = "cosign version";
    version = "v${version}";
  };

  meta = with lib; {
    homepage = "https://github.com/sigstore/cosign";
    changelog = "https://github.com/sigstore/cosign/releases/tag/v${version}";
    description = "Container Signing CLI with support for ephemeral keys and Sigstore signing";
    license = licenses.asl20;
    maintainers = with maintainers; [ lesuisse jk developer-guy ];
  };
}
