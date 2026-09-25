#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

git add .
nix run home-manager/master -- switch -b backup --flake ".#miket5"

# Install the pinned Pi coding agent CLI (idempotent).
"$repo_root/scripts/install-pi.sh"
