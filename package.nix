{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.157.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1wja8lqwmcz5mi55bqr7lq0kfywfqlpch5945px3g0cf0a71x379";
    "aarch64-unknown-linux-musl" = "0lv2n5fv3245r5lv5shz5drym5bvhs0p86wmn97hvzf5q4biqssc";
    "x86_64-apple-darwin" = "084s3j8gf404iqdj789gyzr9b41nv8di0r9b3q6vfqjzdf09n6i8";
    "aarch64-apple-darwin" = "1yllb2jrnz63c9bwsncvgadj2wrc26ld1c8ma0r52vx7nxib2i9w";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1z6pfblkkf6523mbkf8h7x5ikavyl69v54nvggp0dg76pfwgj5im";
    "aarch64-unknown-linux-musl" = "13iipfbmr24g885sshd3amvj5s192syrwc14mmvrm3m9dn044dz8";
    "x86_64-apple-darwin" = "15hcbdh70m58krxk6lvd9ws2rsvrjkw4j5szax0bpzrqdgyair9z";
    "aarch64-apple-darwin" = "05432diwyzjklhnr8i8rmjqjzxwb9b3fmpzvr1hmrpvhr79350r8";
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
