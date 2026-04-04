# nixac — Nix-managed macOS developer environment

A minimal, **no-sudo** home-manager configuration for macOS (Apple Silicon). Manages your shell, editor, terminal, and dev tools declaratively through Nix while keeping Homebrew separate for GUI apps.

## What you get

| Tool | What it does | Managed by |
|------|-------------|------------|
| **Neovim** (LazyVim) | Editor with LSPs, treesitter, plugins | Nix (binary + LSPs), LazyVim (plugin config) |
| **tmux** | Terminal multiplexer with catppuccin theme | Nix + Home Manager |
| **Ghostty** | GPU-accelerated terminal | Homebrew (app), Nix (config) |
| **zsh** | Shell with vi-mode, fzf-tab, autosuggestions | Nix + Home Manager |
| **Starship** | Cross-shell prompt with catppuccin theme | Nix + Home Manager |
| **Atuin** | Shell history search (SQLite-backed) | Nix + Home Manager |
| **Git** | Multi-identity support (personal + work) | Nix + Home Manager |
| **Lazygit** | Git TUI | Nix + Home Manager |
| **Aerospace** | Tiling window manager for macOS | Homebrew (app), Nix (config) |
| **Firefox** | Browser with privacy policies + extensions | Homebrew (app), Nix (policies) |
| **OpenCode** | Claude terminal assistant | Homebrew/npm, Nix (config) |
| **direnv + devenv** | Per-project dev environments | Nix + Home Manager |
| **SOPS + age** | Encrypted secrets (SSH keys, API tokens) | Nix + Home Manager |

## Prerequisites

- macOS on Apple Silicon (aarch64-darwin)
- [Homebrew](https://brew.sh) installed
- About 10 GB of free disk space for the Nix store

## Quick start

### 1. Install Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This installs the **Determinate Nix Installer** — the recommended way to get Nix on macOS. It:
- Does NOT require sudo after initial install
- Sets up the Nix daemon automatically
- Enables flakes and nix-command by default

After install, **restart your terminal** (or `source /etc/zshrc`).

Verify it works:
```sh
nix --version
```

### 2. Install Homebrew GUI apps

Nix manages CLI tools and configs. Homebrew manages GUI `.app` bundles:

```sh
# Required
brew install --cask ghostty firefox aerospace

# Optional
brew install --cask zen-browser obsidian spotify bitwarden raycast
```

### 3. Clone and personalize

```sh
git clone <this-repo-url> ~/nixac
cd ~/nixac
```

Edit `home.nix` — change username and home directory:
```nix
home = {
  username = "YOUR_USERNAME";       # run: whoami
  homeDirectory = "/Users/YOUR_USERNAME";
  ...
};
```

Edit `modules/git.nix` — change git identity:
```nix
settings = {
  user = {
    name = "your-github-username";
    email = "you@example.com";
  };
  ...
};
```

If you have a work git identity, update the `includes` block or remove it.

### 4. Build and activate

```sh
# First time: enter a dev shell with home-manager available
nix develop

# Build and switch
home-manager switch --flake .
```

After the first switch, `home-manager` is in your PATH permanently. Future switches:
```sh
# Or just use the alias (defined in zsh config):
hs
```

### 5. Restart your shell

```sh
exec zsh
```

Open Ghostty, and you should see your full environment: starship prompt, vi-mode, fzf-tab completions, tmux ready.

## Using devenv / direnv

This config ships with **direnv + nix-direnv** pre-configured. To create isolated dev environments per project:

### Option A: devenv (recommended for beginners)
```sh
cd ~/my-project
devenv init
# Edit devenv.nix to add languages/tools, then:
direnv allow
```

### Option B: Plain flake
```sh
cd ~/my-project
nix flake init
# Edit flake.nix to add a devShell, then:
echo 'use flake' > .envrc
direnv allow
```

When you `cd` into the project, tools are automatically loaded. When you `cd` out, they're unloaded. No global installs needed.

## Secrets management with SOPS

SOPS lets you store encrypted secrets (SSH keys, API tokens) in git. They're decrypted at `home-manager switch` time using your age key.

### Initial setup (one-time)

```sh
# 1. Generate your age keypair
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. Get your PUBLIC key (share this, it's safe)
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1abc123...
```

### 3. Add your public key to `.sops.yaml`

Edit `.sops.yaml` in the repo root:
```yaml
keys:
  - &your_name age1abc123...   # paste your public key here

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *your_name
```

### 4. Create / edit secrets

```sh
# Create encrypted secrets file (opens $EDITOR)
sops secrets/secrets.yaml
```

In the editor, add your secrets as YAML:
```yaml
git_ssh_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAA...
    -----END OPENSSH PRIVATE KEY-----
```

Save and quit — SOPS encrypts automatically.

### 5. Enable sops SSH in git config

Edit `modules/git.nix` and set:
```nix
enableSopsSSH = true;
```

Then rebuild:
```sh
home-manager switch --flake .
```

Your SSH key is now decrypted to a runtime path and configured in `~/.ssh/config` automatically.

### Adding teammates

Each person:
1. Generates their own age keypair (step 1-2 above)
2. Shares their **public** key
3. You add it to `.sops.yaml` and re-encrypt:
   ```sh
   sops updatekeys secrets/secrets.yaml
   ```
4. Commit and push — they can now decrypt on their machine

## Nix vs Homebrew — what goes where?

| Install via | What | Why |
|-------------|------|-----|
| **Nix** (this config) | CLI tools, shell plugins, LSP servers, formatters, configs | Reproducible, declarative, pinned versions |
| **Homebrew** | GUI `.app` bundles (Ghostty, Firefox, Aerospace, Slack, etc.) | macOS apps with proper code signing, Spotlight integration |
| **devenv/direnv** | Project-specific tools (node 20 for project A, python 3.12 for project B) | Isolated, automatic, no global pollution |

**Rule of thumb**: If it has a dock icon, use Homebrew. If it runs in a terminal, use Nix.

## Directory structure

```
nixac/
├── flake.nix                 # Nix flake — inputs (nixpkgs, home-manager, sops-nix)
├── flake.lock                # Pinned dependency versions
├── home.nix                  # Main config — imports all modules
├── .sops.yaml                # SOPS key mapping (who can decrypt what)
├── secrets/
│   └── secrets.yaml          # Encrypted secrets (safe to commit)
└── modules/
    ├── sops.nix              # Secrets management (age + sops-nix)
    ├── git.nix               # Git multi-identity + optional sops SSH keys
    ├── tmux.nix              # Tmux with catppuccin, vim-navigator, sesh
    ├── ghostty.nix           # Terminal config (app installed via brew)
    ├── starship.nix          # Prompt with catppuccin mocha theme
    ├── atuin.nix             # Shell history
    ├── lazygit.nix           # Git TUI
    ├── aerospace.nix         # Tiling WM config (app installed via brew)
    ├── firefox.nix           # Browser policies + extensions
    ├── opencode.nix          # Claude terminal assistant config
    ├── zsh/
    │   ├── default.nix       # Zsh + direnv + fzf + zoxide + eza
    │   ├── fzf-widgets.zsh   # Ctrl+g sesh, Ctrl+y accept
    │   ├── git.zsh           # git_current_branch / git_main_branch helpers
    │   └── completions.zsh   # fzf-tab styling
    └── neovim/
        ├── default.nix       # Neovim + LSPs + treesitter
        └── lazyvim/          # Full LazyVim config (lua)
```

## Key bindings cheat sheet

### tmux (prefix: `Ctrl+Space`)
| Key | Action |
|-----|--------|
| `Ctrl+Space h/v` | Split horizontal / vertical |
| `Alt+h/j/k/l` | Resize panes |
| `Alt+1-5` | Switch tmux windows |
| `Ctrl+g` | Session picker (sesh + fzf) |
| `Ctrl+Space K` | Lazygit popup |
| `Ctrl+Space F` | Yazi file manager popup |

### Aerospace (alt = Option key)
| Key | Action |
|-----|--------|
| `Alt+h/j/k/l` | Focus window (vim-style) |
| `Alt+Shift+h/j/k/l` | Move window |
| `Alt+6-9` | Switch to workspace 6-9 |
| `Alt+t/b/i/...` | Switch to named workspace (T=Terminal, B=Browser, etc.) |
| `Alt+Shift+f` | Toggle fullscreen |
| `Alt+Tab` | Workspace back-and-forth |

### zsh
| Key | Action |
|-----|--------|
| `Ctrl+y` | Accept autosuggestion |
| `Ctrl+g` | Sesh session picker (outside tmux) |

## Common tasks

### Update all Nix packages
```sh
cd ~/nixac
nix flake update
home-manager switch --flake .
```

### Add a new CLI tool
Edit `home.nix` and add to `home.packages`:
```nix
home.packages = with pkgs; [
  # ... existing packages ...
  htop    # add new tool here
];
```
Then `home-manager switch --flake .`

### Add a new Homebrew GUI app
```sh
brew install --cask <app-name>
```
No Nix changes needed — brew and Nix stay independent.

## Corporate / Intuit Setup

If you're on a corporate-managed Mac (CyberArk, Jamf, Zscaler), there are extra steps.

### 1. Fix SSL for Corporate Proxies

Corporate proxies (Zscaler, Netskope) perform TLS inspection with their own CA. Nix will fail with `self-signed certificate in certificate chain` until you point it at the proxy's CA bundle.

The Nix installer (Lix or Determinate) creates `/etc/nix/macos-keychain.crt` containing corporate CA certs, but doesn't configure Nix to use it.

```sh
# Verify the issue
nix eval --impure --expr 'builtins.fetchurl "https://api.github.com"'
# If this fails with SSL errors, proceed below

# Test the fix
NIX_SSL_CERT_FILE=/etc/nix/macos-keychain.crt nix eval --impure --expr 'builtins.fetchurl "https://api.github.com"'

# Make it permanent
sudo tee /etc/nix/nix.custom.conf > /dev/null << 'EOF'
ssl-cert-file = /etc/nix/macos-keychain.crt
EOF
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

### 2. Install Homebrew (without admin group)

On CyberArk/Jamf-managed machines, the standard Homebrew installer may fail because your user isn't in the `admin` group. Use the manual method:

```sh
sudo mkdir -p /opt/homebrew && sudo chown -R $(whoami):staff /opt/homebrew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C /opt/homebrew
```

Verify:
```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version
```

### 3. Intuit-specific Homebrew packages

These are managed outside of Nix since they require access to Intuit's internal GitHub:

```sh
# EIAM CLI — Intuit AWS credential authentication
brew tap intuit/eiamcli git@github.intuit.com:EIAM/eiamCli-golang.git
brew install eiamCli

# JankyBorders — active window border highlighting (used with Aerospace)
brew tap FelixKratz/formulae
brew install borders
```

**Note:** The `intuit/eiamcli` tap requires SSH access to `github.intuit.com`. Make sure your work SSH key is configured first (see Secrets section above).

### 4. Required Homebrew casks

GUI apps that Nix doesn't manage (install via brew):

```sh
# Required
brew install --cask ghostty firefox aerospace

# Development
brew install --cask docker cursor

# Optional
brew install --cask zen-browser obsidian spotify bitwarden raycast karabiner-elements
```

**MDM note:** Some casks may be blocked by corporate MDM (Jamf). If `brew install --cask` fails for an app, install it through the IT self-service portal instead.

### 5. Git SSH for Intuit GitHub

After setting up SOPS secrets (see above), your `~/.ssh/config` will have entries for both:
- `github-personal` → `github.com` (personal repos)
- `github.intuit.com` → `github.intuit.com` (work repos)

For Intuit repos, clone using the internal hostname:
```sh
git clone git@github.intuit.com:your-org/repo.git ~/dev/intuit/repo
```

Repos under `~/dev/intuit/` automatically use your work git identity (`spadia` / `shyam_padia@intuit.com`).

### 6. Touch ID for sudo

After first `home-manager switch`, Touch ID should work for sudo. If it stops working after a macOS update:
```sh
# macOS updates sometimes overwrite PAM config — just rebuild
home-manager switch --flake ~/nixac
```

### Corporate troubleshooting

| Issue | Fix |
|-------|-----|
| `self-signed certificate in certificate chain` | Check `/etc/nix/macos-keychain.crt` exists; run the SSL fix above |
| `sudo: nix: command not found` | Use `sudo env PATH="$PATH" nix ...` or full path `/nix/var/nix/profiles/default/bin/nix` |
| Homebrew cask blocked by MDM | Install via IT self-service portal, or skip the cask |
| Touch ID stopped working after macOS update | Rebuild: `home-manager switch --flake ~/nixac` |
| `eiamCli` tap fails | Ensure SSH key for `github.intuit.com` is working: `ssh -T git@github.intuit.com` |
| `tv update-channels` SSL error | `SSL_CERT_FILE=/etc/nix/macos-keychain.crt tv update-channels` |

---

### Troubleshooting

**"experimental-features" error**: Your Nix install doesn't have flakes enabled. Add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

**"collision between" error**: Two packages provide the same binary. Add one to `home.packages` with `lib.lowPriority` or remove the duplicate.

**Build fails after `nix flake update`**: A package was renamed or removed upstream. Check the error for the package name and find the replacement in [search.nixos.org](https://search.nixos.org/packages).

**Git config is read-only**: The activation script creates a writable wrapper. If it didn't run, try:
```sh
rm ~/.config/git/config
home-manager switch --flake .
```
