{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.164.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1r789rvirk39nqzx9vs7ffj1cafv2fs76krsfgxbgz4an81hppch";
    "aarch64-unknown-linux-musl" = "1sq8j77phjri5l9ydph2g5fx36fjh7965dwn9gcnr3zxlfi0g999";
    "x86_64-apple-darwin" = "0x8fz8mr4f058gv5xkb8rcj5kb9asszxy9izvmnpycsn7h0vqsyy";
    "aarch64-apple-darwin" = "0hj1kapmnnizzq2wjln2kgdvxgf944kashsmq2m120fqd70rk0ma";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0bsg4bpvax8jfw2cag8nk2ysva42xz3m10495vla9finch1fgbgy";
    "aarch64-unknown-linux-musl" = "1lijvn8g2m91p5kirqzfwx7xrwn4m6x3adk935av0cav9pids2qf";
    "x86_64-apple-darwin" = "04c2hk4r5sck97rpm8szqkr8dvi2r2qvjgd21aa8hx342da3vyah";
    "aarch64-apple-darwin" = "05g4ci63bw8q6nmx9m7j14xh4axjdk29jf93fr58ig37fmlwmhvv";
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
