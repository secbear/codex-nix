{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.149.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1zac4h26fngw3p4fnfss1kjb1rrymzsvjnv9lbz5f8fhbq2v4s3k";
    "aarch64-unknown-linux-musl" = "1fx95cm4mlv5hx29l975j66zhia7wnqyn2xfmz44ic5s5x6fphqw";
    "x86_64-apple-darwin" = "0r8f885qh4880p087w3flm5ipqv0cc81pyq5kvyj2nvmlkzpb2n7";
    "aarch64-apple-darwin" = "1ijgwzimclysh5ifc4d801xfgl9p6fvavqjd9g66nyxg56b4zvqc";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0k50881lvz3608mch2f48s5kishz2dh9ix7ljp4y77xhq9da801n";
    "aarch64-unknown-linux-musl" = "08jb8xjzpqsv6r49h1xalp78572hmh27g9q4pdpjxi6j12iskx5b";
    "x86_64-apple-darwin" = "1zb1bl3mw4vxr6fgwgsqghm20firyv82nrlw0gmd306jzjaqd70y";
    "aarch64-apple-darwin" = "0i5jpy8vw4q5d8qjj86pfqfn3fhi0ryfwhh63zpjgrshkh46lspd";
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
