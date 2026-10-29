{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.166.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0y1rrf4z6zl0cyzdfpw8yf2dqy30x54a6v9af735dw4k5wnmggx0";
    "aarch64-unknown-linux-musl" = "1a8hz2vwzf5yx55c6dv2n41cyg3v9rydyzjvw2r4c9pc0mv71swl";
    "x86_64-apple-darwin" = "0mvvyr6sf98p5zkrq74yz7l4qnn3hs9n5lf8ww99n69n7iqkh36v";
    "aarch64-apple-darwin" = "1ma0w99ylbxlf3sh8fb1fl2032dm25xxj989zgm82xn55x329264";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1nlhfplxghm4fqlsgfp9n68q8mz4s7adyw0bjwyh1i3vsi7k723m";
    "aarch64-unknown-linux-musl" = "1rq1jyhxddmnwag83pcv20acixpjzrxx87vip9na2lz3g3wd365c";
    "x86_64-apple-darwin" = "0rdgri1agj1cshvk52p2s2v21wxvbd71brqdbv8613azbrfpfp5k";
    "aarch64-apple-darwin" = "1if7qm3dwxrm0kla6jqwiyhr6w655nw5zi4knskrad03bzz51gbs";
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
