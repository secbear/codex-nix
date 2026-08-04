{
  description = "Nix flake for codex — OpenAI Codex CLI, an AI coding agent for your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # x86_64-darwin is absent deliberately: nixpkgs 26.11 dropped it, so
      # instantiating pkgs for that system throws. package.nix still carries
      # its hash, so the overlay keeps working on nixpkgs 26.05.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, ... }:
        let
          codex = pkgs.callPackage ./package.nix { };
        in
        {
          packages = {
            default = codex;
            inherit codex;
          };

          apps.default = {
            type = "app";
            program = "${codex}/bin/codex";
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ codex ];
          };
        };

      flake = {
        overlays.default = final: _prev: {
          codex = final.callPackage ./package.nix { };
        };
      };
    };
}
