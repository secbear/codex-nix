{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.159.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0lb8vp74irwy9ysyspba78vi02blay1myzf216lg7sh03fs8pbs7";
    "aarch64-unknown-linux-musl" = "15dg40vfh8gim1v5rhvd4yznyl4jir5g3ifr14b6x6zgb1ybxrw4";
    "x86_64-apple-darwin" = "1f05bkx76jdj62ppd0wm7gjhzdmxk00bc4n78js453p1csc4h6h4";
    "aarch64-apple-darwin" = "0pwl2a2h1bysfp22p5kp86gddd216p8clr5icfz6p8pxl9p0i62h";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1g2l1npv8s3lilq7b4fxzfwg7qgws0nng4sjnldfvglxnfyl91iv";
    "aarch64-unknown-linux-musl" = "024vivyjib5akpfc7z547p4871xn8i9mymklkag8irk9vknbg5ma";
    "x86_64-apple-darwin" = "1xxbpvrllnv0zcdf82wb4dq390mwp7iwha5w18k798gblhal6hdd";
    "aarch64-apple-darwin" = "0xggr4vypmv1wwlr05gmmwfsj42r4j4brby7as1wnxqklqn7jkjp";
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
