{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.152.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "04calb4wwzdzr7jj8as6n7dp5zmnjwkwwmmdxpcsrdf5sg9l5y85";
    "aarch64-unknown-linux-musl" = "131fijq4jgagbwifjlfjdn4xz26kh0yjlkb0qhna9j03cm46pnip";
    "x86_64-apple-darwin" = "0dihcfnfl6iwwcdpf8zvsli39zdr3l0q0jz9zh19b82rfk3cb36f";
    "aarch64-apple-darwin" = "1hdg70i2lhxbwwikap5dq6554w5c7xd7z31h47lkag7pqq3f96jw";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1fkwd2v622la57l7vvmzn1g84dwv6cbfh8givczpwd4zbgiyz724";
    "aarch64-unknown-linux-musl" = "1sb76bqvrj03q0rrs26xvc59ar0s1pqgqp5i9gnla8mvyp3q6h8k";
    "x86_64-apple-darwin" = "103v6ljlzls4y8faa3im3pbcqrxg0h9jyzlw44k1hqmm36zymzc6";
    "aarch64-apple-darwin" = "1p57w1kidbjxvl7nw9dk0f3b26f40f818c8asz29w8mqf16bs49x";
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
