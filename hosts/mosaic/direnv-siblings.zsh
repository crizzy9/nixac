# One .envrc per Mosaic dev root is shared by every worktree under it
# (hosts/mosaic/envrc explains the whole mechanism). direnv never re-evaluates
# on its own when you move between two directories governed by the same
# .envrc, so this hook deletes the "active worktree" marker(s) that no longer
# match the cwd. The .envrc watches its own marker; that file vanishing is what
# makes direnv reload and evaluate for the new worktree. Moving around INSIDE a
# worktree deletes nothing, so nothing reloads.
#
# MOSAIC_ROOT is exported by the envrc, so this runs only while a Mosaic root
# is loaded and never needs to know where the roots are. The key must match
# the envrc's: git toplevel relative to the root, / → __, or _none.
_mosaic_direnv_siblings() {
  [[ -n ${MOSAIC_ROOT:-} ]] || return 0
  [[ $PWD == $MOSAIC_ROOT || $PWD == $MOSAIC_ROOT/* ]] || return 0 # left the tree: direnv unloads by itself
  local markers="${XDG_CACHE_HOME:-$HOME/.cache}/direnv/mosaic-active"
  [[ -d $markers ]] || return 0

  local top key="_none"
  top=$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)
  if [[ -n $top && $top == $MOSAIC_ROOT/* ]]; then
    key=${${top#$MOSAIC_ROOT/}//\//__}
  fi

  local m
  for m in "$markers"/*(N); do
    [[ ${m:t} == $key ]] || command rm -f -- "$m"
  done
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _mosaic_direnv_siblings
