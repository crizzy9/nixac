# Eza (ls replacement) aliases
alias la = eza -la --icons auto --group-directories-first
alias lsag = eza -lah --icons auto --git --group-directories-first
alias lsat = eza -lah --icons auto --git --tree -L 2 --git-ignore

# JSON utilities (macOS clipboard)
def jj [] {
  pbpaste | jq . | pbcopy
}

def jjj [] {
  pbpaste | jq .
}

def jjn [] {
  pbpaste | jq . | nvim - +'set syntax=json'
}

# Prefetch a git URL from the clipboard into a nix fetcher expression
def pfg [] {
  let url = (pbpaste | str trim)
  nurl $url | pbcopy
}

# Git helper functions
def git_current_branch [] {
  git symbolic-ref --quiet HEAD
    | str replace 'refs/heads/' ''
    | str trim
}

def git_main_branch [] {
  let branches = [main trunk mainline default stable master]
  for branch in $branches {
    let check = (git show-ref -q --verify $"refs/heads/($branch)" | complete)
    if $check.exit_code == 0 {
      return $branch
    }
  }
  return "master"
}

# Git aliases using functions
alias gopull = git pull origin (git_current_branch)
alias gopush = git push origin (git_current_branch)
alias gprom = git pull origin (git_main_branch) --rebase --autostash
alias gprum = git pull upstream (git_main_branch) --rebase --autostash
alias glom = git pull origin (git_main_branch)
alias glum = git pull upstream (git_main_branch)
alias gluc = git pull upstream (git_current_branch)

# Nix shell package helper
def nsp-run [pkg: string, command: string] {
  ^nix-shell -p $pkg --run $command
}

# Nix dev-shell helper functions
# Templates come from the upstream that lumino's modules/dev-shells was copied
# from. Override with $env.NIXAC_TEMPLATES to point at a local checkout.
def nixac-templates [] {
  if ("NIXAC_TEMPLATES" in $env) { $env.NIXAC_TEMPLATES } else { "github:the-nix-way/dev-templates" }
}

def fnew [dir: string, template: string] {
  if ($dir | path exists) {
    print $"Directory \"($dir)\" already exists!"
    return
  }
  ^nix flake new $dir --template $"(nixac-templates)#($template)"
  cd $dir
  "use flake" | save -f .envrc
  ^direnv allow
}

def finit [template: string] {
  ^nix flake init --template $"(nixac-templates)#($template)"
  if not (".envrc" | path exists) { "use flake" | save -f .envrc }
  ^direnv allow
}

# Find store path for a package
def find-store-path [pkg: string] {
  ^nix-shell -p $pkg --command $"nix eval -f '<nixpkgs>' --raw ($pkg)"
}
