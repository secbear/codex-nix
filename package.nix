{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.172.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "14p3dgns7kb1b62pfqdmls9jq5l4rglwy33262z8iw38gy7jld52";
    "aarch64-unknown-linux-musl" = "17p7hdgf35xypspvg0qq8z0zg9x6nsvly8d2jvz2ai2s31n5568b";
    "x86_64-apple-darwin" = "12i7in4w1l5jcn95khaa5da56hnvdl4jpkmhww2n681m2lm9g80h";
    "aarch64-apple-darwin" = "14ih0mkfky38gw83k7d1xn4kxa15iqs4m83d8zyb6a3bpn51y4mx";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1d1b6l75a02lyvdrydqcmwkkcv5g0hyr8k4ijxcmlh9jyfya9c10";
    "aarch64-unknown-linux-musl" = "0s6w80w1x8gy7bxf6vzr3kc9x8x9i497bqs09n9kmsjklfx7wqxn";
    "x86_64-apple-darwin" = "0lyz5lmzhxlz64xy4xm1z0p68vz1vfxl87a0prf2lb03zkjpz4wg";
    "aarch64-apple-darwin" = "1r5n5kh20anixayccvjq9jlikz90w87ggdqiihfqh372ws44zcpa";
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
