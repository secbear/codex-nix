# codex-nix

Nix flake for [OpenAI Codex CLI](https://github.com/openai/codex) (the Rust CLI, `codex-rs`) — an AI coding agent for your terminal.

Packages the latest official pre-built binaries so you can use `codex` declaratively on NixOS, nix-darwin, and Home Manager without building from source.

## Quick Start

```bash
nix run github:SecBear/codex-nix -- --version
nix profile install github:SecBear/codex-nix
```

## Using as a Flake Input

```nix
{
  inputs.codex-nix.url = "github:SecBear/codex-nix";

  outputs = { nixpkgs, codex-nix, ... }: { ... };
}
```

### nix-darwin / NixOS

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.codex-nix.packages.${pkgs.system}.default
  ];
}
```

### Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.codex-nix.packages.${pkgs.system}.default
  ];
}
```

## Platforms

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS    | aarch64 (Apple Silicon) | Supported |
| macOS    | x86_64 (Intel) | **Not supported** — see below |
| Linux    | x86_64 | Supported |
| Linux    | aarch64 | Supported |

### macOS x86_64 (Intel)

Nixpkgs 26.11 [dropped support for `x86_64-darwin`](https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.11).
This flake follows `nixpkgs-unstable`, so `x86_64-darwin` is no longer in its
`systems` list — evaluating it would throw before it ever reached this package.

The package itself is platform-agnostic: `package.nix` still carries the
`x86_64-apple-darwin` URL and hash, and `scripts/update.sh` keeps them current.
If you are on an Intel Mac, use the overlay against a nixpkgs that still
supports the platform (26.05 receives security fixes until the end of 2026):

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  inputs.codex-nix.url = "github:SecBear/codex-nix";

  # pkgs = import nixpkgs { overlays = [ codex-nix.overlays.default ]; ... };
  # then: pkgs.codex
}
```

## Updates

`.github/workflows/update.yml` checks hourly for a new **stable** codex release.
When one appears it rewrites the version and every platform hash — one set for
the `codex` CLI and one for its `codex-code-mode-host` companion — builds the
result, then opens a PR and merges it. `Build` runs on Linux and macOS after
the merge, and a successful build tags `v<version>` and moves `latest`.

Prereleases are ignored — the check resolves the latest non-prerelease release,
so `0.147.0-alpha.N` and friends never land automatically. To take one anyway:

```bash
gh workflow run update.yml -f version=0.147.0-alpha.6
```

> [!NOTE]
> GitHub disables scheduled workflows after 60 days without repository
> activity (this happened on 2026-06-23, and updates stopped silently for
> three weeks). Automatic updates keep the repo active on their own, but if
> the version ever looks stale, check that `Check for Updates` is still
> enabled: `gh workflow list --repo SecBear/codex-nix`.

To update manually:

```bash
./scripts/update.sh          # update to latest
./scripts/update.sh --check  # check only
./scripts/update.sh 0.105.0  # specific version
```

## Related

- [openai/codex](https://github.com/openai/codex) — upstream project
