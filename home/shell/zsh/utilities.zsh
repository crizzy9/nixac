# ========== #
# dev-shells
# ========== #
# lumino vendors ~50 language templates under modules/dev-shells/ and exposes
# them as a flake `templates` output. nixac does not vendor them — it points at
# the upstream those were copied from. Override with NIXAC_TEMPLATES to use a
# local checkout instead, e.g.:
#   export NIXAC_TEMPLATES="$HOME/lumino/modules/dev-shells"
: "${NIXAC_TEMPLATES:=github:the-nix-way/dev-templates}"

function fnew {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: fnew <directory> <template>   (e.g. fnew myapp node)"
    return 1
  fi
  if [ -d "$1" ]; then
    echo "Directory \"$1\" already exists!"
    return 1
  fi
  nix flake new "$1" --template "$NIXAC_TEMPLATES#$2" || return 1
  cd "$1" || return 1
  echo "use flake" > .envrc
  direnv allow
}

function finit {
  if [ -z "$1" ]; then
    echo "usage: finit <template>   (e.g. finit python)"
    return 1
  fi
  nix flake init --template "$NIXAC_TEMPLATES#$1" || return 1
  [ -f .envrc ] || echo "use flake" > .envrc
  direnv allow
}

#==================#
# Custom Functions #
#==================#
function nsp() {
  nix shell nixpkgs#$1
}
