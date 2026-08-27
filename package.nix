{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.150.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0yjw2n87mgl8cqnqinmrk7yfg75gp3v077f47p14ih3zpiq8hc5b";
    "aarch64-unknown-linux-musl" = "0r4j2vhvmsxhi95a544d59fbx55kna7wkwii99dq920m39gggcav";
    "x86_64-apple-darwin" = "1anhs4s0kk59gynci3y359vha55bh6v1cjdy7ys45jy22fqxw2yh";
    "aarch64-apple-darwin" = "1dn7dxh64hp47vr2746d2f4hq6qj4kpgm1pgi9m9v97dy52iqvzn";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1iagxs6v1gmzkfclsky54qwyzcmg332gvik0qkdzdk95c626fxml";
    "aarch64-unknown-linux-musl" = "173gza8vyzfp7rzjx46zhc07y2gjwz5jbq4n62npgskdlf54m4yc";
    "x86_64-apple-darwin" = "1p4gd8zlrn3c9pjnmy8wq2g2r33wfm9vw3rzmgcycn0g896vn8m9";
    "aarch64-apple-darwin" = "1gy14xmmaxkqpr1jn29jkl9wy2llwzny42wkn45ha2n3v80jhd0f";
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
