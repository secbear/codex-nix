{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.167.2";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0pxi4l0lwvrf51mfshpajig8kjhd4yy6fh6cgwcj3sjhqm3fhil2";
    "aarch64-unknown-linux-musl" = "1paalrpzca1b2hcl0b0w5blqs8alsmg30vqv0spqk5i0glngm0gd";
    "x86_64-apple-darwin" = "12nn7fb0bfqf97g4rl3bbqsqddb5nyq33iq0xvq5jw2qdbkp3xqc";
    "aarch64-apple-darwin" = "1pw18v5g00bfgjnr53gwckzwrza54nyr5412w7qbqlh1g8xic4bm";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "19ir5k879nf39vlac7gj5idkwv8h6hkz5zldw1vafb6qajk7b50q";
    "aarch64-unknown-linux-musl" = "1kl2kw9gpf3ykw7hqlb89bzh0jnz3j2gqmshw1ks4xfb0pql721w";
    "x86_64-apple-darwin" = "1imf2mr779asxas82dcg0hzvbh0yini959bl19lbnad6lb55as9g";
    "aarch64-apple-darwin" = "1khcjhrbrx0pppnhiml94q1s4vm4dk7lq37hzadsfd7h08bq8pji";
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
