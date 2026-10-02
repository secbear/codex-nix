{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.160.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "04sasikwpb73ban91lxdb7hy2hbza8592ljqg0kskrsfgm0nas1h";
    "aarch64-unknown-linux-musl" = "1mz9xl22m95b20f7nydviqw23x6pl63vm59cl7jpgxi5k49j0dl8";
    "x86_64-apple-darwin" = "1gszh9kz1fizfxqj1kw47ivvralmamisnsvv5zfvi0afdrh10355";
    "aarch64-apple-darwin" = "0pabi623gnaj0rfi5f19z9yfjdysil9m6brl2l8pk3va6z5cghq7";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1b4c0dgb8bmql7b77g1xyca1yr8ifz9wz8gb6dmg8f8fiwldcv5c";
    "aarch64-unknown-linux-musl" = "13h3866090jxbkr6yg9fchx2hh1hzjw5rv3nhzsx5v7z2ggny1ll";
    "x86_64-apple-darwin" = "0hglv494c68qpb2rnmvhwqabzdyrivgh0alp6ikknbpccsiyn95h";
    "aarch64-apple-darwin" = "0xddb80kkqzvskfjgj2avghgabbwis68092l7npfbjlxdv3znw6w";
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
