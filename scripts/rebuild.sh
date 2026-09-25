#!/usr/bin/env bash
# nixac rebuild — one entry point for both flake outputs.
#
# Auto-detects which mode this machine is in:
#   darwin-rebuild present  → darwinConfigurations.<hostname>  (system + home)
#   otherwise               → homeConfigurations.<username>    (home only)
#
# Force either with --mode darwin | --mode home.
#
# Usage: ./scripts/rebuild.sh [action] [--update] [--mode darwin|home]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-help}"
UPDATE=false
MODE=""

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update|-u) UPDATE=true; shift ;;
    --mode|-m)
      [[ -z "${2:-}" ]] && { echo "Error: --mode requires darwin|home" >&2; exit 1; }
      MODE="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: nixac targets macOS only." >&2
  exit 1
fi

# Read identity straight out of hosts/*.nix so this script never drifts from
# the config. Falls back to live values if the greps fail.
HOSTNAME_ATTR="$(grep -m1 'hostname *=' "$REPO_DIR"/hosts/*.nix | sed 's/.*"\(.*\)".*/\1/' || true)"
USERNAME_ATTR="$(grep -m1 'username *=' "$REPO_DIR"/hosts/*.nix | sed 's/.*"\(.*\)".*/\1/' || true)"
HOSTNAME_ATTR="${HOSTNAME_ATTR:-$(hostname -s)}"
USERNAME_ATTR="${USERNAME_ATTR:-$(whoami)}"

if [[ -z "$MODE" ]]; then
  if command -v darwin-rebuild >/dev/null 2>&1 || [[ -e /run/current-system ]]; then
    MODE="darwin"
  else
    MODE="home"
  fi
fi

if [[ "$MODE" == "darwin" ]]; then
  FLAKE="$REPO_DIR#$HOSTNAME_ATTR"
else
  FLAKE="$REPO_DIR#$USERNAME_ATTR"
fi

# Flakes only see git-tracked files — stage new ones (intent-to-add, no commit).
cd "$REPO_DIR"
git add -N . 2>/dev/null || true

_update() {
  if $UPDATE; then
    echo "==> Updating flake inputs..."
    nix flake update --flake "$REPO_DIR"
  fi
}

_build() { # $1 = darwin action, $2 = home action
  if [[ "$MODE" == "darwin" ]]; then
    echo "==> darwin-rebuild $1 --flake $FLAKE"
    sudo darwin-rebuild "$1" --flake "$FLAKE"
  else
    echo "==> home-manager $2 --flake $FLAKE"
    home-manager "$2" --flake "$FLAKE"
  fi
}

case "$ACTION" in
  switch|sync)
    _update
    _build switch switch
    ;;
  build)
    _update
    _build build build
    ;;
  dry|dry-run)
    _update
    if [[ "$MODE" == "darwin" ]]; then
      sudo darwin-rebuild build --flake "$FLAKE" --dry-run
    else
      home-manager build --flake "$FLAKE" --dry-run
    fi
    ;;
  check)
    _update
    nix flake check "$REPO_DIR"
    ;;
  generations)
    if [[ "$MODE" == "darwin" ]]; then
      darwin-rebuild --list-generations
    else
      home-manager generations
    fi
    ;;
  rollback)
    if [[ "$MODE" == "darwin" ]]; then
      sudo darwin-rebuild rollback
    else
      echo "home-manager has no rollback; activate an older generation:" >&2
      echo "  home-manager generations   # pick one, then run its activate script" >&2
      exit 1
    fi
    ;;
  fmt)
    nix fmt "$REPO_DIR"
    ;;
  help|*)
    cat <<EOF
nixac rebuild — mode: $MODE   flake: $FLAKE

  switch | sync   build and activate
  build           build without activating
  dry             build with --dry-run
  check           nix flake check
  generations     list generations
  rollback        roll back one generation (darwin mode only)
  fmt             nix fmt the repo

Flags:
  --update, -u        nix flake update first
  --mode, -m MODE     force darwin | home  (default: auto-detected)
EOF
    ;;
esac
