{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.157.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0yv5q364hrzb0dq3vdhgjs939zl2fw8qm64anvghxi9mmany6gyv";
    "aarch64-unknown-linux-musl" = "0pyjlw5zmjrjdy3y370l9an40cj4yw841hrvgqzq66wlirwy5yz6";
    "x86_64-apple-darwin" = "0wybk18250nc7q3n72d73fpmcgp0zxi17c9ivwrqmwwdz20wry5v";
    "aarch64-apple-darwin" = "02c98crdmzhshfmhad2f3lzp42qac0y8mypjifsvpj7q5cv2458g";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "174qy5wi9iibbw7afggdzpiz03i5zc5qk8k4nvdwvjcmx0cj9ls7";
    "aarch64-unknown-linux-musl" = "04690pnm2am50gg8f8yq9wm52z408i641c7w1q4zhsz16n0kac9v";
    "x86_64-apple-darwin" = "0m97q5hb493d01pgcqsn9mrxc13sqba355i7j5mybh4pxbcdx6wc";
    "aarch64-apple-darwin" = "0mr3dnq6ahb6rd2n952ppi2jgkpiraag3fszi38380d5qzv3zcx5";
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
