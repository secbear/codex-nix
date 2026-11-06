{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.167.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "06i5vbmjd7sbld0pxgaqcl8afz6ypiz4qig41vlp9cym0rhq6r4x";
    "aarch64-unknown-linux-musl" = "10djivp36kjqagyhiwjs2n1pp21vjv2h6sy38nbhgcflnjn8jd44";
    "x86_64-apple-darwin" = "088jw02hkx1rlvs3jnvj066rgc5swlipad0hvsf325qbba34msyq";
    "aarch64-apple-darwin" = "1saz8bb5v9nbkhlaf4jqlrjbv3m8fwz2z48zwg1r29xyf6ls48jb";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1m3xy1n9lpy4wb0i4zx2yp0k3zwfb154jzljfg0b4hs6srfls1xm";
    "aarch64-unknown-linux-musl" = "1ihys5gpcb5rdgbi3mmy1kh23cv1lapmcai23yh1da0cla7r96bf";
    "x86_64-apple-darwin" = "14fcplhscswl3f7cgm2mdavqb8j0szs9c9wjxq2vyvriqz10sbb1";
    "aarch64-apple-darwin" = "0qxm7rgk1jpfn1x1a5gxrr0i24jw5b2mpkz5xbd0xvs86ck3wsl7";
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/rust-v${version}/codex-${platform}.tar.gz";
    sha256 = hashes.${platform};
  };

  # codex spawns codex-code-mode-host from its own directory to run code mode
  # out of process. Upstream ships it as a separate release asset, so without
  # this every code-mode tool call fails with "failed to spawn code-mode host".
  codeModeHostSrc = fetchurl {
    url = "https://github.com/${repo}/releases/download/rust-v${version}/codex-code-mode-host-${platform}.tar.gz";
    sha256 = codeModeHostHashes.${platform};
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp codex-${platform} $out/bin/codex
    chmod +x $out/bin/codex

    tar xzf $codeModeHostSrc
    cp codex-code-mode-host-${platform} $out/bin/codex-code-mode-host
    chmod +x $out/bin/codex-code-mode-host

    runHook postInstall
  '';

  # Upstream ships statically linked musl binaries on Linux and Mach-O
  # executables on Darwin: nothing to patch, strip, or link against.
  dontFixup = true;

  meta = {
    description = "OpenAI Codex CLI — an AI coding agent for your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/${repo}/releases/tag/rust-v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "codex";
  };
}
