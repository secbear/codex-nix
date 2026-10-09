{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.162.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0msh2bxf13skf9dikmj2w015hb6s5ynz5ksy9ha3x3w93gc6iwl6";
    "aarch64-unknown-linux-musl" = "1h804q5wdkmzz28pkbah5iw6qscy6x4w31dx1x2b2hqikxqs4g5z";
    "x86_64-apple-darwin" = "088vqbisrcrawqkkhjk6ks0gfglwrda6ar80glzz6f96yvc3k3nn";
    "aarch64-apple-darwin" = "1znigwbx3mcbvgmr1xsl53h326s0mahl0kqa9jj006c7vpya14xj";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1nls7424yvs6lhlnk958153q7wjjnc51hpv9i66m1z618pm3k0j5";
    "aarch64-unknown-linux-musl" = "16hy33lxsgsgppam30wbj0fj5gr5vwz0izsdcy0d5b7qcy9wx58k";
    "x86_64-apple-darwin" = "0dqx265fizag8xap34dhfp7ps3lrpjchqvgkm8wq5cc4d25aylnd";
    "aarch64-apple-darwin" = "09rp5fb83ibq4pa3drhkgv7qbd1cxydz2sqv8dp93g5djhl4lihz";
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
