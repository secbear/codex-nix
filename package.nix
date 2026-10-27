{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.165.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1w47w4hajzvh35bxhk9l6462hq01sgk2ln7z1w6hdgd5hqs5sqxy";
    "aarch64-unknown-linux-musl" = "1lzmmg9pd5qarjcj8m42nw8hiisvw0daij8mm4fm6zxys1bf08k5";
    "x86_64-apple-darwin" = "14wrr5q1d6hd7rq9h6r73nhf46x4404cvgmq059dzsrn35s52r7l";
    "aarch64-apple-darwin" = "0i31pf9hs8ilabk882nysvb2z45bkqxxz5343pkzvj1dilbrrskq";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0pi30m7ylwip268669amfwhamysqdpg0g650m0yynvjl5adv0xwm";
    "aarch64-unknown-linux-musl" = "0qabx7qbfkzv6v9ncm4wwnj2xzfjnxc5j8wz09l8f4d24p1mc2a0";
    "x86_64-apple-darwin" = "13fbr1cxky1zabj53prys7galcxji2zwkafxmykbbh6c3ycyzx5d";
    "aarch64-apple-darwin" = "0446v8dn7dhscscv54qr80vhw42gcajjqgvmsc21vsan6vfsfqfq";
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
