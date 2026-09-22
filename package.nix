{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.156.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0yswajr7q04vz0a7rbjrqa1k1ciqn85543p5a7y8q5m54npxjj9x";
    "aarch64-unknown-linux-musl" = "18n598hlpvaazgrvz0bqj28d3k60zpgjx7fafwvzv9qp4rkpmlbp";
    "x86_64-apple-darwin" = "1chwvmjlpqvhq9n8365wr666a4yk2byi0zjpwva87m43whrkdlci";
    "aarch64-apple-darwin" = "1hra4355is49qldnvgjyas4lxlhrwvb4576gck2pp2knagjy1nih";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0fz5r94s8sdvh08zrfcidrmdj2jm3pz4i98w3bq7fkvb1fdwg0w3";
    "aarch64-unknown-linux-musl" = "1c76z0h6897awniwwrss8csxslmck7hjh9kjbvyl3cq7w92ml9nq";
    "x86_64-apple-darwin" = "0v3mb6i8sdsvia1q1f4j16pxjyj4p6xm2f0gri891qdiy4sajrhi";
    "aarch64-apple-darwin" = "1virfw93f2ycilbhl2wa1aqnw6hci70zqnz2ssr6c1c202gpxr3p";
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
