{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.169.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1hb06vpxfiwzji7a0d31sa937g2njknr33v2llmcmr7kxbh870xx";
    "aarch64-unknown-linux-musl" = "1gwy5ikrqv54x9rdq8ydbmyrik9da1pfxw4w0q43kf6hqv3wg70a";
    "x86_64-apple-darwin" = "1hw9mdch3wmg2xdm9vv473qhldvyxx20d3vg1b6a1qz1094bdjbl";
    "aarch64-apple-darwin" = "1z55wsxzw5jj122p62l4msjv78n61gdzl6rdsyjqqpf1iqrm3cj1";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0vhi57qpjpmgcz2a0bczwdhzvahcidz2f43y6kxpwycbmmssm6a3";
    "aarch64-unknown-linux-musl" = "0bvj04hzmfadsin0vgzc2s9zz88bk9iz40pbjnff648gyw0kdi8n";
    "x86_64-apple-darwin" = "0k23fl25qkgbqirhbm5as86nms119vg9cbja86pvsnwmfwrvsqbk";
    "aarch64-apple-darwin" = "1mdixlm522zshf3ri7ls21qzzrg5igmmyryn60ifdkw49s7zr2ra";
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
