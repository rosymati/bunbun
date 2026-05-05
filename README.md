# bunbun

A Nix flake that packages [Bun](https://bun.sh) for Linux, updated daily via GitHub Actions. Usually days or weeks ahead of nixpkgs.

## Why

nixpkgs has a long review cycle. New Bun releases land on GitHub, but they take time to reach nixpkgs-unstable, let alone stable channels. This flake runs an automated update job every morning at 06:00 UTC: if there's a new release, it fetches the binaries, prefetches the SRI hashes, patches `bun.nix`, refreshes `flake.lock`, and pushes a commit. No manual steps.

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`

musl-based systems are marked broken. macOS is out of scope.

## Usage

Add the flake as an input:

```nix
# flake.nix
inputs.bunbun.url = "github:puppymati/bunbun";
inputs.bunbun.inputs.nixpkgs.follows = "nixpkgs";
```

**Overlay** (replaces `pkgs.bun` everywhere):

```nix
nixpkgs.overlays = [ inputs.bunbun.overlays.default ];
```

**Direct package** (if you only want it in one place):

```nix
environment.systemPackages = [
  inputs.bunbun.packages.${system}.default
];
```

## CI

The update workflow runs daily at 06:00 UTC and can be triggered manually via `workflow_dispatch`.

Each run:

1. Checks out the repo and installs Nix.
2. Runs `update.sh`: queries the GitHub releases API, compares the latest version to what's in `bun.nix`, and if there's something newer, prefetches both zip archives (`bun-linux-x64.zip` and `bun-linux-aarch64.zip`) to get their SRI hashes, then patches `version` and both `hash` fields in place.
3. Runs `nix flake update` to refresh `flake.lock`.
4. Commits `bun.nix` and `flake.lock` with a message like `bun: 1.3.12 -> 1.3.13` and pushes.

If nothing changed, it exits without committing.

## Manual update

To bump to a specific version ahead of the daily run:

```bash
bash update.sh
nix flake update
```

To fetch a hash for a single architecture:

```bash
nix store prefetch-file --hash-type sha256 --json \
  "https://github.com/oven-sh/bun/releases/download/bun-vVERSION/bun-linux-x64.zip" \
  | jq -r '.hash'
```

To build and smoke-test locally:

```bash
nix build .#packages.x86_64-linux.default
./result/bin/bun --version
```

## License

MIT
