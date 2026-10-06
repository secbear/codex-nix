{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.160.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0gx3pf28r26k16dypxrrbvj63ak3vcpka2klgxz8zlcjwldmh9lj";
    "aarch64-unknown-linux-musl" = "1xz1yyc5bp3kvrs41851qm92zc1wdwak3am33ps5ni22422wakgm";
    "x86_64-apple-darwin" = "1drdy1xblzr2lak04cs61skmlk2ixn26jq7i8lflnhn4jgdqv4wd";
    "aarch64-apple-darwin" = "1l4496a5334mv0fh0xbil09ks0y561gkinnpfkxmmjfr96qg42k7";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1hp3w0jvn4mmgm8hdkzabnp52k3swvhp8naqnr9wfnjljxyj0sca";
    "aarch64-unknown-linux-musl" = "0hcprxyvkjfn5qahwd8351iiifqfkwbh19haazis5zcyd3k2gq75";
    "x86_64-apple-darwin" = "0ix1pc4lk6kfrlf4q49fb72n3286dyjqfcjy0sfanv1c3izfc2nd";
    "aarch64-apple-darwin" = "1ny703l27f6vhh019z4i8lfsnccgp8bpqg0cbcqgl84jkpv2sl3f";
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
