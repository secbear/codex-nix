{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.155.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "05cibl5lg0d2id4pc8nc1nn004z39lskk85i0xz79gy3xcnqpvx0";
    "aarch64-unknown-linux-musl" = "1mx2ykqylrp376hvfbd442lk4pbh2c39v4pk0kp553b8plpydiyn";
    "x86_64-apple-darwin" = "14bpq8jcp9jcfszii48gz9q53zji8jk0xvr8zgdni1cby85ss8pz";
    "aarch64-apple-darwin" = "0s1pgah4gbwf2zskv0x690l0xk64pg893lbbv7wj696f1m3m2njy";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0bbv0qkksdw7f0b8z4x3d9dny4xm3wvisdgbmhcfhnzm79s87l4z";
    "aarch64-unknown-linux-musl" = "10qnhsvfi79isws6gqlp79fdq6zdfr2qzh6kfhh6rsaadpbjwvsi";
    "x86_64-apple-darwin" = "0sh6d1apzw0dx4ng6v44qknz8bsrs7fy4w3wl0zw2hlqldvj67ad";
    "aarch64-apple-darwin" = "12jh3c3x89f685q199vj35ylfavsgzmpr18614xrcw5xxq4735g8";
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
