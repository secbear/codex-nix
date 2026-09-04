{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.153.3";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1flcyixfvd40wzhygg9yqmd6xjxkxa48gg284x67650fn15ngybg";
    "aarch64-unknown-linux-musl" = "06dz6s0s4095pzzhhx1l446jibrxi6x6c3d38imlzpip56r7xzv8";
    "x86_64-apple-darwin" = "067jfi5ym321anjvjzx1cnv7hbv7z0641sypgp7hl4fs706dn6f6";
    "aarch64-apple-darwin" = "1kannflik19l9cw6s8dz4q5v1qcx6a02aq3gmcn6yqf1fkccpk82";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0lzgkb329laixdlydx3fxagwxqv8k225v9varmfrv3fj8lq67bhh";
    "aarch64-unknown-linux-musl" = "1kjalg3ixmfd1m11d99svgab0vabgdi7qj7gxfdb0bzy8a0bji0z";
    "x86_64-apple-darwin" = "1c1978lim2sfh5qbggygq0w1a846spvxks74r1djb73bgxsikn7s";
    "aarch64-apple-darwin" = "0s884315kd26m3ilx8s08bnz3b6baamwgwwhvm7z4ad8k42889rv";
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
