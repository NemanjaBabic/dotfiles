#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$DIR/.." && pwd -P)"
ln -sfn "$REPO_ROOT" ~/.dotfiles
exec sudo darwin-rebuild switch --flake ~/.dotfiles/unix#mac
