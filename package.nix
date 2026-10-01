{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.159.3";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1jqv54dz7vgx6pf4qs0n35jj93l9gj9ksb708jwl5gxissra335l";
    "aarch64-unknown-linux-musl" = "19xynhp5asw716z4gi0xqvqx8rsa271qcjv87rvq0q6d7xxk0pyd";
    "x86_64-apple-darwin" = "1dr4xpa73zsqyx9p5hv9shianhd52ip4f6vwrnkvi29idlhaibnb";
    "aarch64-apple-darwin" = "0k3p2ap859k5i789nvdrnqf1i0n2912lgq2alsqbb4m5ksim1pji";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0f6lmgrhxvhd1jpxf85yii58yfplr0grrqr3a8p3h5y792cdsn0g";
    "aarch64-unknown-linux-musl" = "0vwfkf8ia9klb53d3xgq9cvfnrmz27zm5gzfpxd13p62fb24gfvw";
    "x86_64-apple-darwin" = "17yb5y34xjpn3izjadg1jf7s7nzdzsx4mj2lf59xj35wqnr8awyj";
    "aarch64-apple-darwin" = "1ifl2pgqk8fyadiij723wdqzhgjyyqhfpjrizbqzycxpfi1jb8yi";
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
