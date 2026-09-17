{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.155.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1h5nxh5a18zjvmp5s6p55r5w6710m5cdvd24impf3bclvcxcq5g4";
    "aarch64-unknown-linux-musl" = "0jv9qnz5zf13lyzxv2kmr6y724zsp00qm49zr7vibi8nd4srqjlb";
    "x86_64-apple-darwin" = "0x41a5r7rz2dq3sz9w57wpffp38win0jim5qr08flki82ldhi16c";
    "aarch64-apple-darwin" = "0jdsrlfd10mvlpv0ahgnnwk1a8y4bc7z2lysra1p1af2vmy4nn2s";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1m2lg15awdrv53sq727fh61v3lsklgz6wmwl6w2jgiwzw3mip31j";
    "aarch64-unknown-linux-musl" = "16s8smvryihcbfyfm5lp1hn0b8zbmzmwkikd1ivj1db86hk8xk8f";
    "x86_64-apple-darwin" = "17glds30831ard5majamldzfnn6g0s5skh21w07m16ygv9piqp98";
    "aarch64-apple-darwin" = "0szshyrxqcqvmm95gr0plzvsnwmqzsar7702hvq2ci8vz7p1sx9x";
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
