#!/usr/bin/env bash
# nixac bootstrap — take a fresh macOS machine to a first nix-darwin build.
#
# Idempotent: every step checks whether it is already done and skips if so.
#
# Steps:
#   1. Install Nix — the OFFICIAL installer, deliberately NOT Determinate.
#      Determinate ships determinate-nixd, which requires nix.enable = false
#      in nix-darwin and would silently discard darwin/nix-settings.nix.
#   2. Install Homebrew — nix-darwin manages casks but never installs brew.
#   3. Generate a sops age key (optional; prints the public key to add to
#      .sops.yaml). Secrets stay dormant until you do that AND flip
#      features.sops = true in hosts/mosaic/default.nix.
#   4. First build:  sudo nix run nix-darwin -- switch --flake .#<hostname>
#      Afterwards use ./scripts/rebuild.sh (aliased to `hs`).
#
# Usage: ./scripts/bootstrap-darwin.sh [hostname]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME_ARG="${1:-}"

# Flakes aren't enabled in a stock nix.conf; nix-darwin takes that over after
# the first switch. Pass them explicitly until then.
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    ! %s\033[0m\n' "$*"; }

[[ "$(uname)" == "Darwin" ]] || { echo "Error: macOS only." >&2; exit 1; }

# The Homebrew installer refuses to run as root. Run as your normal user; the
# script prompts for sudo where it genuinely needs it.
[[ "$(id -u)" -ne 0 ]] || { echo "Error: run as your normal user, not with sudo." >&2; exit 1; }

HOSTNAME_ATTR="${HOSTNAME_ARG:-$(grep -m1 'hostname *=' "$REPO_DIR"/hosts/*.nix | sed 's/.*"\(.*\)".*/\1/')}"
[[ -n "$HOSTNAME_ATTR" ]] || { echo "Error: could not determine hostname; pass it as an argument." >&2; exit 1; }

echo "Repo:     $REPO_DIR"
echo "Host attr: $HOSTNAME_ATTR"

# Pre-authenticate sudo once. Homebrew's NONINTERACTIVE mode checks `sudo -n`,
# which only passes with cached credentials, and later steps need sudo anyway.
step "sudo"
sudo -v
ok "authenticated"

# ── 1. Nix ────────────────────────────────────────────────────────────────
step "Nix"
if command -v nix >/dev/null 2>&1 || [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  ok "already installed"
else
  echo "    Installing via the official installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install | sh -s -- --daemon --yes
  ok "installed"
fi
if ! command -v nix >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] \
    && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || { echo "Error: nix still not on PATH — open a new terminal and re-run." >&2; exit 1; }

# ── 2. Homebrew ───────────────────────────────────────────────────────────
step "Homebrew"
if [[ -x /opt/homebrew/bin/brew ]]; then
  ok "already installed"
else
  echo "    Installing..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "installed"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── 3. sops age key (optional) ────────────────────────────────────────────
step "sops age key (optional)"
AGE_KEY="$HOME/.config/sops/age/keys.txt"
if [[ -f "$AGE_KEY" ]]; then
  ok "already present: $(nix "${NIX_FLAGS[@]}" run nixpkgs#age -- -y "$AGE_KEY" 2>/dev/null || echo '<run age-keygen -y to print>')"
else
  warn "no age key at $AGE_KEY"
  echo "    Secrets are OFF by default (features.sops = false), so this is not required."
  echo "    To enable later:"
  echo "      mkdir -p ~/.config/sops/age"
  echo "      nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt"
  echo "      # add the printed public key to .sops.yaml, then:"
  echo "      nix run nixpkgs#sops -- secrets/secrets.yaml"
  echo "      # finally set features.sops = true in hosts/mosaic/default.nix"
fi

# ── 4. First nix-darwin switch ────────────────────────────────────────────
step "First nix-darwin build"
cd "$REPO_DIR"
# Flakes ignore untracked files — a missing `git add` shows up as
# "flake output attribute 'darwinConfigurations.$HOSTNAME_ATTR' does not exist".
git add -N . 2>/dev/null || true

if command -v darwin-rebuild >/dev/null 2>&1; then
  ok "nix-darwin already installed — using darwin-rebuild"
  sudo darwin-rebuild switch --flake ".#$HOSTNAME_ATTR"
else
  echo "    Bootstrapping nix-darwin (this builds the whole closure — expect a while)..."
  sudo nix "${NIX_FLAGS[@]}" run nix-darwin -- switch --flake ".#$HOSTNAME_ATTR"
fi

step "Done"
cat <<EOF

  Open a new terminal, then:

    hs                 rebuild + activate   (scripts/rebuild.sh switch)
    update             update inputs + switch
    dry-run            build without activating

  Manual steps macOS cannot grant declaratively:
    • AeroSpace        → System Settings ▸ Privacy & Security ▸ Accessibility
    • aerospace-swipe  → same panel; RE-GRANT after every rebuild that changes
                         its store path, then kill the stray detached process
                         (\`pkill -f aerospace-swipe\`) so launchd owns it again
    • Karabiner        → Input Monitoring, on first launch
EOF
