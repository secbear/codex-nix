{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.153.4";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0c2ah46q14z465hms13098il1k7l8j6f4ynq83f88909r9744ygl";
    "aarch64-unknown-linux-musl" = "1pkc3c3sbhf6907xf56vzn8zdxzbi5a4jfmn5q7s7hwlpn163njw";
    "x86_64-apple-darwin" = "194zrblghhhh9fjfh6mrpb14ybiafk7q02zq0wd1s6w4pzq014nn";
    "aarch64-apple-darwin" = "1cahk0mkydd3v2s6slxdj145dfiain263i8y2arby8v5czm13ycc";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0cfdnj4ny5q8b7qvlw1nd5mq0ww7n367pimz9dk5f2ard6l30n7r";
    "aarch64-unknown-linux-musl" = "0fw11p3mvc69730l7hd1pa32c2p6dnvpxli9wy86039p6f6pn16q";
    "x86_64-apple-darwin" = "1xrvprpk8h8m0yxs0g4g28p8dnjri189lhaqqcr655rx238fpyig";
    "aarch64-apple-darwin" = "1pziklcha8lh805bakx1lwl175hfv5fif7mrdddbi61vypyv1aa5";
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
