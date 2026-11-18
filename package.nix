{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.170.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1xa7w8629vmqpsx4pm7w827wm12ihxy2z3bb6wh3i998rmn92m6h";
    "aarch64-unknown-linux-musl" = "1g3yzz9bxzk06f16h3b2xzi9cra6s4dq8gm7ll0kj8mmyrhv19hd";
    "x86_64-apple-darwin" = "18x555g0ppsz3n3fm9ivlaz1hgwm9ly198a0i37sh0xh940vnn68";
    "aarch64-apple-darwin" = "1adrqacl26ryg1c4nwgxfkl9qfgz17vxr7rp9g8n0j5frgaj37vw";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1iadz8i8aw7kahdfama82mi65mlg0raivfiybh490s2qf3cjkaqq";
    "aarch64-unknown-linux-musl" = "0nbaz081x3gb1zcq03gli866nn6ar6xdnypkzx15iallsk2p3s4a";
    "x86_64-apple-darwin" = "0hf70pwqwhsii0ancvfrql607rslplxl3ir7i6w3sxqnalijl297";
    "aarch64-apple-darwin" = "1jpvssxpb3a9llv7vr1ibpj5hajr7xqnl0kzxd9gqns47c18r93g";
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
