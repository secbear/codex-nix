{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.152.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1l4z538gx16wp4aw7ajjrc30nrs6pk70xq4sy10b75ymn501pvd0";
    "aarch64-unknown-linux-musl" = "1g6y4m2wldyzdfm24ih43jwa2hd72viq4iwgi65r8alp0139cpxn";
    "x86_64-apple-darwin" = "1s4zz1ymvj5w2klps65rjg1qg9qy3p2gg6yp94xzjw2wa2bs9k4q";
    "aarch64-apple-darwin" = "1mxrcikrih2xwi246vmqzqwjmclb104c3iq9madjx169ypyf3pcd";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1vci85m14107v4g8ckjmvgwyxf0y89iqw7d9d7bsx28ybi6m86hg";
    "aarch64-unknown-linux-musl" = "1ws3ff4c8r2f6q8xmypnjhwag3kja0njdi0sm9lwz99jn6ps3i11";
    "x86_64-apple-darwin" = "0xpgg4y5lpzai9q50gwnqrc1bwsndyhyvbiki6xjmfx87y4fw26y";
    "aarch64-apple-darwin" = "0qskngxrgy5djdkb56p5z17wbqgp0y58b8byri2wbj1m7v5xs7cv";
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
