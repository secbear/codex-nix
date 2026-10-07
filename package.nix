{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.161.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1wnfl0lx59gpn29byy40ah6ipspj4f5631rqb8p7y3b6jx8bkvxi";
    "aarch64-unknown-linux-musl" = "0sm2lla3iinjwf71wbikrdp8wcgf6liyqa7vr8pwczy9wd5vz42w";
    "x86_64-apple-darwin" = "0lrq8srbg3f8fcxixw90gq3bza2c0413c3hvpzm71w0mbci74gfb";
    "aarch64-apple-darwin" = "0f7x3hhcasbazcix3fxgyxisfgx6qbxn88gc0z2785727aglg0xx";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1y3p9zzby0gpc5qskwrg89y1vgrk9a22zk45wdgd3vmkfxgr9k1h";
    "aarch64-unknown-linux-musl" = "1bc48fmm9hzzsyf0gmhqlxs9ks7gjhlh8rsl3ch2rs3cb3405yda";
    "x86_64-apple-darwin" = "13z730yqcw2c8zkcbrpdflb35jrqrm25kymbkxl7fylziclzavr8";
    "aarch64-apple-darwin" = "0i66qiqg046g0iv7iq1bl7c6cifahpxg7xlsy6rlqc2iihaj84l2";
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
