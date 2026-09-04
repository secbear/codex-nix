{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.153.2";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "17lpy3yncvpg4xfi4wk3165zq638vmri1f6a20m5swhz0xh13kg8";
    "aarch64-unknown-linux-musl" = "0ap6ljxc17ixd7g37izjl6d7syv8ynhrxyck2yi0wckhngwr71l7";
    "x86_64-apple-darwin" = "0ypf476fbpp8619pbrjga5d0jnlplmxq4a7yqjhmahmi4zgiaifq";
    "aarch64-apple-darwin" = "1770x6gvgwxy0r0fd11pkvf78zpjsj8amw8lv0bfrfnzy1qc5pwi";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0jmy5qs2zxfpys7m1gd8fsl72slznfblc0xc2gqrfzycp43layhp";
    "aarch64-unknown-linux-musl" = "01xzpk4x22z905rmk1gf6rgrm8c2aym73gkhbyvki80rd5g4izkh";
    "x86_64-apple-darwin" = "12zi68zvih4947gc0qk5k2llx968lizag9q0vvvlbr4y4vyqf1g1";
    "aarch64-apple-darwin" = "02rhahcbqph0m9pz23im1za6fdimf11x31zc9klwpys1c55faw9l";
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
