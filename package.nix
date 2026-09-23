{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.156.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0gak2hfw0l1sy3x9la6zz68m7nah5k72nn9cqviqdzrsm0wnbx5g";
    "aarch64-unknown-linux-musl" = "0wlvyx23yh2s300lzmh6d1s592nv46bvyh3jqig37jyslsm153jm";
    "x86_64-apple-darwin" = "1psld9bd6gs5v76mlw94bfsy7jgz5xij4425jkfj0dz5vs34bqsm";
    "aarch64-apple-darwin" = "1jm525qi422f2hia4yrcrjd1jyfg4p8xbgznyaapgm7d9pqlmmib";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0266crz2rhwrdi7mb7bgv6n2bc8py4nl1rn9q00drgd0yslxlad9";
    "aarch64-unknown-linux-musl" = "155y1ibcgh52q8872jqhx9s6g2d5iix84k6sq2lgz61pn0w826a0";
    "x86_64-apple-darwin" = "02bj3l4z7wy15225ph09h4w5yz5hycv2hvalw6qzpmqjfag8v5pw";
    "aarch64-apple-darwin" = "1ncvywgr4x4fi9im8a1df8y5vhii1073wyj3rhmkvq5nw8ix0996";
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
