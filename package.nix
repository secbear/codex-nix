{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.159.2";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1shn2qw15dldy9096w5k443zpw3hsfny33pgn2csfhbd4h6nnn16";
    "aarch64-unknown-linux-musl" = "03wkgs41bxwm7sh002f0vcv713f1kayn40dz5dwzi934jkaf8bj7";
    "x86_64-apple-darwin" = "1s9vxzrlxxrqy1qs361ld6fg2z45yy0ffrnx08yxvc85m9qiykiz";
    "aarch64-apple-darwin" = "0g618fbpkrgp8lyvm29z4zj98z3wqrfmhblmxy49vjfbhkyyyp82";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "03v3yz3qmi027vv1rmn6xc6scg9qc40br3i0s4l0gv94gd50qszv";
    "aarch64-unknown-linux-musl" = "0c34inck7hn5d35ddcyb8gnqqh0621p66qyxcc4p7vsygrrnf681";
    "x86_64-apple-darwin" = "1hbw0rmhnhvbd1fip6mkwig837n9dds8jk88p73sgapc0iqd3ryg";
    "aarch64-apple-darwin" = "1wl2wjlimm03gw5qhlcp5zl26d2jr56b0swl53hvxsdb7q73r7sg";
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
