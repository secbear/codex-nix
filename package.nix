{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.159.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1h6bx50nfav39cx7kh61nm0rvgxwnhbpxc4qqlb9hn9rrc47ln3f";
    "aarch64-unknown-linux-musl" = "0vf1bzl1wd4gg3axf6amhxazkkzv8aa98gda7ni8yqp7h1fyg90n";
    "x86_64-apple-darwin" = "1zmp2nvalx40hkvfg2fx60pjmaarqn53mqn30c1zi5kim29sqwbc";
    "aarch64-apple-darwin" = "0cwxfd1ac1gw5hiy54sikclrydja9ly543whbbmynr6hq81zwvwp";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0iz9bfc6jhxn16w21kjmqw540rgcs3hc1hm0kh7k5mwkwxljklpr";
    "aarch64-unknown-linux-musl" = "1djfdkcgwyn3iz66vxirdgdrbfzw56jggfpq1q4bbv9qpnnch2ab";
    "x86_64-apple-darwin" = "004dpwx04lg69fl90pc3km78b1m2drf7xf9mh1vjadacm4c1qqsa";
    "aarch64-apple-darwin" = "02p1ickg50i2b7gapkfaz2rzwmnkqr8i7qa3040zmlcxzwv5dda0";
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
