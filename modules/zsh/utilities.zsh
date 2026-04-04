# ========== #
# dev-shells
# ========== #
function fnew {
  if [ -d "$1" ]; then
    echo "Directory \"$1\" already exists!"
    return 1
  fi
  local dotfiles="${DOTFILES:-$HOME/nixac}"
  nix flake new $1 --template $dotfiles/modules/dev-shells#$2
  cd $1
  direnv allow
}

function finit {
  local dotfiles="${DOTFILES:-$HOME/nixac}"
  nix flake init --template $dotfiles/modules/dev-shells#$1
  direnv allow
}

#==================#
# Custom Functions #
#==================#
function nsp() {
  nix shell nixpkgs#$1
}
