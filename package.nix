{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.163.0";
  repo = "openai/codex";

  platformMap = {
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  hashes = {
    "x86_64-unknown-linux-musl" = "1r6x91v7j658dh2wa3xzvwp82x54ijnq3p5jddx0bfnrxkl3kcxy";
    "aarch64-unknown-linux-musl" = "1r7z3x3akzffi83lh7ilzkg36b6wy9n9q1jslr68yvd9yijiw9m7";
    "x86_64-apple-darwin" = "1cf7q72ib90h86yg2h2dzl15yw1kmrld51vn8qx2i1jn1vm1lajn";
    "aarch64-apple-darwin" = "043d5xii004svp5lanfy0s565npnfg38g7qx1hmv9g914nlxki31";
  };

  codeModeHostHashes = {
    "x86_64-unknown-linux-musl" = "0a9mf0xl5j901dgfpgywf8mnk2ljmzp5s9kwh1z2wnd6ic966hii";
    "aarch64-unknown-linux-musl" = "1vql6ascrdv4w3fpdfc93zmg7k78pbyzsblidfvh0zqrzfp5chr8";
    "x86_64-apple-darwin" = "1zg1gilbbqfp27p13zpnrky3hviaq81mjmbfg6jlpj32a3nwc4aj";
    "aarch64-apple-darwin" = "0hcriv4cwcgp728b96bihd6yf6s8jqmnk4iwhj37bab78ydg8a1f";
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
