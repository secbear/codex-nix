{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.171.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "13ayq5b71ndap8plql3frddzpqyzwkaapy5jwmxmky09g3ja5fh1";
    "aarch64-unknown-linux-musl" = "07474j6sg2ipps6yn4kpwg5s220v5glvpckajz91prc5cf1hpxdw";
    "x86_64-apple-darwin" = "0i5aqxi5f90hprqg1sds6g288sr6bd015wrhpw9alr5azx2136vg";
    "aarch64-apple-darwin" = "06k8l8syabn9c6ji00c9xya2008gnaiczh14hcgb247icz4wh54l";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "13467mppk1mazrzxhqywksfss8zs3dy6crwwki6hm38v1h1ik1np";
    "aarch64-unknown-linux-musl" = "0aynkhpfh68xwcxz8savmc6v2gzgbimrk6fv7pqvasc6ny0whsbn";
    "x86_64-apple-darwin" = "177mbjx48lynhvv6300g8vklm6ryx52mgn9psagmf1kq350npk41";
    "aarch64-apple-darwin" = "19rmcgp0clzsr5f11mmb4skndxqpxjirm7k8a15w935h55n601bs";
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
