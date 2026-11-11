{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.167.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1qp3qip0jq9nn5prfvcmgswwvvkskggrg2jhn2yb8d746afckg34";
    "aarch64-unknown-linux-musl" = "0cjyqzksxf4pxgp7nmw9xzyh94vlz2cfz4d0l40pv9hf80dyrvry";
    "x86_64-apple-darwin" = "0r70rw2jcln8p0rgz964qgzjwasii0392k2kjj0cml00y93wjf8n";
    "aarch64-apple-darwin" = "1yjviyz22piy54qwpw1cf4s5y6cijr43jy8hahi1f7m2zgdgp5sc";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0843qzfdja7ia94r614wb4cfxlf1z6n74ax6c3d8v1zkbnli12nw";
    "aarch64-unknown-linux-musl" = "01v7v5gmckh2aiq5g777zws7rdi9bxqjnza715cq004wq2b3aldn";
    "x86_64-apple-darwin" = "0rfxw1qc0jmalbd6m744f9jnqi0gg639fk8ah09nhr35cp4hjp0s";
    "aarch64-apple-darwin" = "1ha4sfg5cz0c51pdl2lsram55ws8xrkfw7m089dflrjvxq5cxnas";
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
