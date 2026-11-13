{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.169.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "11d93ri49s3vz7s0q4q4xf74bgrd4pakg532xbnzm0z1zi8xgx4s";
    "aarch64-unknown-linux-musl" = "0gvg34vnc9z083dfqlvrcskj45j5d8azdiq9fz5waxd0xs3pvfcp";
    "x86_64-apple-darwin" = "0xg4pj5lnp2hmv1xls0v6il1vgpgws69irpkpa98zf7cfmdf0ava";
    "aarch64-apple-darwin" = "1vj5h4skq796n5g5mrp5gbc7ad5a3zqwvkvs6i70n7df1g44jk3z";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1sxc7bgg0ivmz5ilmvpqpj22xinlfsy7yxjpny98f9p84n6nmvfb";
    "aarch64-unknown-linux-musl" = "0k70dq76pln0dabjkl8122gggl2pcjjschblrix7mnmyspj9g4q5";
    "x86_64-apple-darwin" = "17m7i2jc4a9rm8jxy78vfm55ma846vp9w241089wpa9f4igjilrd";
    "aarch64-apple-darwin" = "1gr771nwbihxnyw1qgizkda2g2k1xqxpsas717a3as15dw7k42yl";
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
