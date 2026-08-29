{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.151.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1xjq01z5n2zixb2axzm6cvxhfx3nj5qmnfpnvvslbii27wc4nnv0";
    "aarch64-unknown-linux-musl" = "1dk9adngv209xlzzizswnipmpl4g5kf546iqd4a1q9jy6ypjpky1";
    "x86_64-apple-darwin" = "0zk53wszp0d6yv78c1gy1w3jk17ps909gq376vdshiir3limppa0";
    "aarch64-apple-darwin" = "0rf94ak2b13i3v3zbmwbj0isniy4xd402cy75flr9lllb73f42b4";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1528w40xz9fh149m999fs0addpz8rhp7kgifnlf34w7h2n1acb9k";
    "aarch64-unknown-linux-musl" = "16548fw0982w0sdn6ihlhzm6m3i5bc5dlw5kvi3xjdspcyb56l8m";
    "x86_64-apple-darwin" = "045w3illim8pi6gkn4d60svjapk3q6mybfqi1vp9slx6q65fjqhz";
    "aarch64-apple-darwin" = "1whnvillalrrrz08w7188h7q2yhb3bgw7ra6rz734ywxiy48gawv";
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
