{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.162.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0wzz80hj83q4wry9sxqnc9061mrjc18jmm6q75cslq8i4vv6gbwd";
    "aarch64-unknown-linux-musl" = "0bsw546kwr36hvp0war6l4j68bmjgl5yq53ln89fby7db6djl5hm";
    "x86_64-apple-darwin" = "0sxjxr1iqvypbn1xa7asn3w88dakngfhm3z8yqbjjpfb0j269brw";
    "aarch64-apple-darwin" = "014iyijzmcmy1nbdlp0xn8dlzm76g3qrz4r36xbswryi3cx43scq";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "15rxw9wzm0l4zrwyvw74ji7x8jkdnx1xca5rjla8xiipyqyvzs6y";
    "aarch64-unknown-linux-musl" = "1sgp7j8dchakfyvqkqxcg57qy84aplclj57ia6ps5x1fbl2rpn8q";
    "x86_64-apple-darwin" = "0j9k44s1l3k055jv872wjpy4s4wkzyw46bfgqxx4cibp2zihdqm7";
    "aarch64-apple-darwin" = "1hndvvk1250lyy6vvy2n3ijjqpl234sgvsr4xkw8jvmsm5zw2mcl";
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
