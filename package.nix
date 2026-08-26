{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.150.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1ckgcxcxb0b37gwqzbjk5dvmd959g059ssa3jw02mr0ffh54172y";
    "aarch64-unknown-linux-musl" = "0cl4j14q6nq73q61hza0pnr2f05j5ydp6vxs98llwgf3hqb2ddqf";
    "x86_64-apple-darwin" = "0mg48b8gr9mlbrka701bf94q90ss59d6yyf154ifsgzjhffpskbg";
    "aarch64-apple-darwin" = "120m36hq6wd7bm20jwv7asnklhxxldji07v7z0gdg7k5r8788abd";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "085r0hqx9s28729yakakdyj5vqw32isfx793jlp0q1xw66gsvyvi";
    "aarch64-unknown-linux-musl" = "12cqv0pcdjh61v1xs99wycx0949zfyrxxblwxlxq8s8r3whb40i0";
    "x86_64-apple-darwin" = "012pgq3nkh0c6hpji0wyppgvp9w21hglcj6fv8jsy7m1fxcgc9cg";
    "aarch64-apple-darwin" = "0pskvvkrdnq030815amm1j6gbw6m7464ggyh9cgakazzl40xyvxa";
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
