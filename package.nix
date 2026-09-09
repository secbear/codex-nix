{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.154.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "00kzq045shxniy3djd6nxp4xnj7gvs89xviibwpj93xfjwjqpqfp";
    "aarch64-unknown-linux-musl" = "09rwld7m42nc4skmg9qzh9047cq6vdd2x31krnyi6hl06bglhfsq";
    "x86_64-apple-darwin" = "1rx630z7l0yfwqznvg3rcahrqpcb0g02bh94lj9v84zqv0vwh68j";
    "aarch64-apple-darwin" = "1mzrrvmiczna671smflqjiy90s8s682g7vsgw29b3hcilnh10hrl";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1xq1mx0xd1jb4nhk64yx98ikmiv1vvvpsrvmw76sfv9wlb6gg3d6";
    "aarch64-unknown-linux-musl" = "1ynbdnv347kipngxnswwfkywfxjz9aavy499wfbb88i05hqgmbi0";
    "x86_64-apple-darwin" = "1zl76fwxpr1i673sd8wzzdxk24kjg7z9qn3av314vx4iwm0n3ym0";
    "aarch64-apple-darwin" = "1bbgr1fn8hs1xwac4c3gk00xpl81wbcdgrsjj18sx6555shf43jh";
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
