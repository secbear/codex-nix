{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.153.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "03k8hsgy6s6ajm58vc7fi9w0b7d61g3lmf1ckkh9v5c37lajra1m";
    "aarch64-unknown-linux-musl" = "0lrajm5723lvz2ygarx81j83ca4jbg73radvcf0w2ladblv0qb6c";
    "x86_64-apple-darwin" = "1p4ayssh54s7ld4rzg8511mmbm9gz4wmfj5lz7jvw7ncsz3hk0v6";
    "aarch64-apple-darwin" = "1q9jrc4v8im6yqg98s0bhiz9f5wm3vchy0bknc7g48xyiq5wvplc";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0b3gm1xqb6nfbbqpxmcgnbwq1qbrv2gaydabx4rk799mbr4pm09b";
    "aarch64-unknown-linux-musl" = "0dkpb9d3ja80bnc7mdvnqg0nghsm6znh7z2lcj3mzjamzc361796";
    "x86_64-apple-darwin" = "1z1g4z20a68kvyw9904j5fjs719zi4x4p0316ai0g4nk8dk9b169";
    "aarch64-apple-darwin" = "1sahblnw794p8ypzcrpkars2ikd503qb8052dy0dbs9n2r3b1zc5";
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
