{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.149.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0y32637nsrm3gwhik7kcgz7rcx0kx5b0yqpvgbb404fpqy2bfkz2";
    "aarch64-unknown-linux-musl" = "1c555mz8yfry1xpyddjph364n9fqa46vji78jklnv5cswc16ipql";
    "x86_64-apple-darwin" = "1vw82bxnirxs0lajdp5cba7090mnnyarr6n53igdsfdpgs1pmzl5";
    "aarch64-apple-darwin" = "019lby9zxwpx9chd3k00i7wz7hrw4wrpzz805i6099nxqrsz8q7d";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1swsnllfdk5186pdsdl2knm1lvk3p0mfxckjplh8giabblz2ryk2";
    "aarch64-unknown-linux-musl" = "017sinp4lag80q8ljnm20wr6j32d5324w850fywkrdbjyyfh4bln";
    "x86_64-apple-darwin" = "1gjvgj7yysyl9nlr2n7plh4krhwrsj3ij8gn0zkhkrm05qsbq91s";
    "aarch64-apple-darwin" = "1zgklilmql7n7a6vswxd6dwswh0i6m3xdbddjzla404p8p4w1qda";
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
