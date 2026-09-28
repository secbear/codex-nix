{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.158.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0y2p1s1vgva7571bdhm9ffhq0f08rbcz1kh7szwwqak6wsk5m7xg";
    "aarch64-unknown-linux-musl" = "0379b6cj6zrg5ajg2ni4r7yk1ys6j68h8pd0hpvahigqbzzgmqwi";
    "x86_64-apple-darwin" = "0sg036ljip899hl1y3f6fjbxsp77ids972brqx8f3jjkbza86fdv";
    "aarch64-apple-darwin" = "12kfiwhnf4z6993rl3lk2a8si82h7lmdqxkk02rka6ffz444l71l";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0g8ys7kdchpynyl59i5zlf2kjradszvaz588f5218dxswi5wcmal";
    "aarch64-unknown-linux-musl" = "1v0wmd2v0bq00lz21vsc2v7w2795iv8vx49m3b9d0nknhknfn6sl";
    "x86_64-apple-darwin" = "0j0vldz8zjjhhmwqj7zf1bdnyr4ca9hh5drz7xkwn2wgh3cyr9xl";
    "aarch64-apple-darwin" = "1d2a1pbmpsjaq2912x9yw1v8jg7ahkyzmzxn0nwd5xbmv8c3jdhr";
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
