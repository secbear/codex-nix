{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.153.1";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "0zs84dyzm47m5r1gsih3zsdkmw00mp8lxn1r9gl0ja8cqkg8q608";
    "aarch64-unknown-linux-musl" = "0r46c4119j5n4xgzvyrbr0rcrhd1ngrn70mf6f663gr4wkvfj9kw";
    "x86_64-apple-darwin" = "08jbpiny2dihbjbad2gyc4b9ckzpwf3gqgvn39462x32mylvl88q";
    "aarch64-apple-darwin" = "09lj8xs5rqhrij2p9770p3sz6wvngkizhlmshr2yaflpqrjkr3w1";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "1c43bxws17k8b7i1nmnnsx3i8xd953ihzwpadsgkq83fb43f2fa5";
    "aarch64-unknown-linux-musl" = "0h6ccla5wjwlqhczcrr2qxdfihxqdycda0am272lhvkh3041dqi5";
    "x86_64-apple-darwin" = "08m9i4w0b23g94f4kzs0vc5mmmqnri019fa6yanjv87n20gv0k8q";
    "aarch64-apple-darwin" = "0y8lp3xgq80aq6a3vdnz4sqx3v9lcarifl58d2y6x5wql64sm1sa";
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
