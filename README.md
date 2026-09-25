# nixac — Nix-managed macOS developer environment

A **nix-darwin + Home Manager** configuration for macOS on Apple Silicon, ported
from the `komashi` host in [lumino](https://github.com/crizzy9/lumino).

The distinguishing feature is that it builds **two ways from one set of
modules**, so the repo survives a move to a locked-down employer without being
restructured:

| Output | Command | What it manages |
|---|---|---|
| `darwinConfigurations.mosaic` | `sudo darwin-rebuild switch --flake .#mosaic` | System **and** home: Homebrew, Touch ID, macOS defaults, fonts, launchd daemons, plus everything below |
| `homeConfigurations.spadia` | `home-manager switch --flake .#spadia` | Home only, **zero sudo**: shell, editor, terminal, git, window-manager config |

`./scripts/rebuild.sh` picks the right one automatically. The `home/` modules are
byte-identical between the two — only a `darwinManaged` flag differs.

### Pick ONE mode per machine

Nothing in this repo needs editing to switch between the outputs — but **do not
alternate between them on the same machine.**

Home Manager resolves its generation profile to
`~/.local/state/nix/profiles/home-manager` whether it runs as a nix-darwin
submodule or standalone. Both routes therefore write the same profile and the
same `~/.config` symlinks, so each switch silently clobbers the other's
generation. `home.packages` also moves between two locations:
`/etc/profiles/per-user/<user>/` under nix-darwin (because
`useUserPackages = true`) versus the Home Manager profile when standalone.

Decide once per machine. `mosaic` uses the nix-darwin output; the standalone
output is there for the *next* laptop if it turns out to be locked down.

### Coverage difference

Installation of GUI apps is the darwin layer's job; their *configuration* is
always the home layer's, so the split falls in an unintuitive place:

| | `darwin-rebuild` | `home-manager` only |
|---|---|---|
| Ghostty, AeroSpace, Karabiner, Obsidian, Raycast, Spotify, Vorssaint | declared casks, installed for you | `brew install --cask …` once, by hand |
| `borders` formula | installed | `brew install borders` |
| **Zen** | Nix-installed | **Nix-installed** (no Homebrew involved) |
| Configs for all of the above | yes | yes |
| Whole shell/editor/CLI stack | yes | yes |
| aerospace-swipe gestures | yes | yes — Nix builds it, and its launchd agent is a *home* agent |

What HM-only genuinely loses:

1. **`nix.settings`** — no `/etc/nix/nix.conf`, so `trusted-users` never lists
   you and the daemon *ignores* the extra substituters. Cache misses become
   local builds until you hand-edit that file with sudo.
2. **Touch ID for sudo** — needs `/etc/pam.d/sudo_local`; manual, and macOS
   updates sometimes revert it.
3. **Rollback** — no `darwin-rebuild rollback` equivalent.
4. **The three macOS defaults** in `darwin/defaults.nix` — set them in System
   Settings.
5. **Declarative Homebrew** — see the table above.

Not lost, despite living under `darwin/`: **fonts** (`home/tools/fonts.nix`
detects the mode and links JetBrains Mono into `~/Library/Fonts/nixac` itself)
and the **Karabiner VHID daemon** (Karabiner's own installer registers one).

---

## Layout

```
nixac/
├── flake.nix               both outputs, defined once
├── hosts/
│   └── mosaic/             everything specific to this machine + job
│       ├── default.nix     ← THE ONLY FILE YOU EDIT for a new machine/employer
│       ├── home.nix        ~/dev/mosaic/.envrc symlink, direnv whitelist, zsh hook
│       ├── flake.nix       Mosaic devShells + service stacks (own flake.lock)
│       ├── devShells/      one module per repo: devShell + process-compose
│       ├── envrc           → ~/dev/mosaic/.envrc, the ONE .envrc
│       └── direnv-siblings.zsh
├── darwin/                 nix-darwin only (needs sudo)
│   ├── homebrew.nix        declarative casks, NON-destructive
│   ├── defaults.nix        macOS defaults — AeroSpace-relevant only
│   ├── fonts.nix           JetBrains Mono Nerd Font
│   ├── security.nix        Touch ID for sudo
│   ├── launchd.nix         Karabiner VHID daemon, JankyBorders
│   └── nix-settings.nix    caches, experimental-features, trusted-users
├── home/                   shared by BOTH outputs
│   ├── shell/              zsh, nushell, neovim (LazyVim), tmux, ghostty
│   ├── tools/              starship, atuin, git, gh + gh-dash, lazygit,
│   │                       yazi, television, sops, fonts
│   ├── desktop/            aerospace (+ swipe), karabiner
│   ├── apps/               zen  ·  firefox (parked, not imported)
│   └── agents/             claude-code, agent-sync  (parked, not imported)
├── scripts/
│   ├── bootstrap-darwin.sh fresh machine → first build
│   └── rebuild.sh          day-to-day switch/build/check/rollback
└── secrets/secrets.yaml    sops-encrypted (dormant by default)
```

## Quick start on a fresh machine

```bash
git clone <this-repo> ~/nixac && cd ~/nixac && ./scripts/bootstrap-darwin.sh
```

That installs Nix (official installer, **not** Determinate — see below),
installs Homebrew, and runs the first `nix-darwin` switch. Afterwards:

```bash
sync        # rebuild + activate   (`hs` is an alias for the same thing)
update      # update flake inputs, then switch
dry-run     # build without activating
```

### Manual steps macOS will not let Nix do

| What | Where |
|---|---|
| AeroSpace | System Settings ▸ Privacy & Security ▸ **Accessibility** |
| aerospace-swipe | Same panel, but it will never *prompt* — a launchd-started store-path binary has no app bundle to ask on its behalf. Add it by hand: **+** → `⇧⌘G` → paste the path from `launchctl list org.nix-community.home.aerospace-swipe`. Must be **re-granted every time the store path changes**; afterwards `pkill -f aerospace-swipe` so launchd owns the process again. Logs: `~/Library/Logs/aerospace-swipe.log` |
| Karabiner-Elements | **Input Monitoring**, on first launch |

---

## Homebrew: Nix declares, but never removes

`darwin/homebrew.nix` sets `onActivation.cleanup = "none"`.

komashi uses `"zap"`, which uninstalls every formula and cask absent from the
generated Brewfile on each activation. With `"none"`, nix-darwin **only ever
adds**. Anything you install by hand:

```bash
brew install --cask whatever
```

survives every rebuild, permanently, and never has to be mirrored into this
repo. `onActivation.autoUpdate` and `upgrade` are also off, so a rebuild will
not bump versions you pinned yourself.

Nix-declared casks: `aerospace`, `ghostty`, `obsidian`, `raycast`, `spotify`,
`vorssaint`, `karabiner-elements`, plus the `borders` formula.
**Firefox is deliberately absent** — you manage it yourself.

---

## Browsers

**Zen** is Nix-managed through
[`0xc000022070/zen-browser-flake`](https://github.com/0xc000022070/zen-browser-flake) —
the same flake lumino uses. It now supports `aarch64-darwin` first-class, so
there is no better macOS-specific alternative:
[`bandithedoge/nixpkgs-firefox-darwin`](https://github.com/bandithedoge/nixpkgs-firefox-darwin)
and [`wuz/nix-darwin-browsers`](https://github.com/wuz/nix-darwin-browsers) are
plain overlays with no Home Manager module, so you'd lose declarative policies,
profiles and extensions.

It runs in `darwin.packageMode = "signed"`, which installs the `.app` untouched
so the upstream code signature survives (keeping 1Password / iCloud Passwords /
Gatekeeper working). The trade-off is that `extraPrefs`, `extraPrefsFiles`,
`pkcs11Modules` and `enableGnomeExtensions` are unavailable — none are used here.

To use the Homebrew cask instead: set `features.zen = false` in
`hosts/mosaic/default.nix` and uncomment `"zen"` in `darwin/homebrew.nix`.

---

## Moving to a restrictive machine

1. Copy `hosts/mosaic/` to `hosts/<newhost>/`, change `hostname` in its `default.nix`,
   `username`, `repoDir` and the `git` block.
2. Point `flake.nix`'s `host = import ./hosts/mosaic;` (and the `./hosts/mosaic/home.nix`
   module) at the new directory.
3. Turn off what the machine won't allow:

```nix
features = {
  homebrew   = false;   # no admin group / MDM-blocked casks
  touchIdSudo = false;  # PAM edits blocked
  borders    = false;   # brew formula
  karabiner  = false;   # needs a system DriverKit daemon
  aerospaceSwipe = false;
  # aerospace / zen / the whole shell stack keep working
};
```

4. Build the no-sudo output:

```bash
home-manager switch --flake .#<username>
```

In that mode `home/tools/fonts.nix` links JetBrains Mono into
`~/Library/Fonts/nixac` itself, since `fonts.packages` is a nix-darwin option.

### Corporate proxies (Zscaler / Netskope)

TLS-inspecting proxies break Nix with `self-signed certificate in certificate
chain`. Point Nix at the proxy's CA bundle:

```bash
sudo tee /etc/nix/nix.custom.conf > /dev/null <<'EOF'
ssl-cert-file = /etc/nix/macos-keychain.crt
EOF
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

If your user isn't in the macOS `admin` group, the standard Homebrew installer
fails; install it manually:

```bash
sudo mkdir -p /opt/homebrew && sudo chown -R $(whoami):staff /opt/homebrew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C /opt/homebrew
```

---

## Secrets (SOPS) — off by default

`features.sops = false`, so `secrets/secrets.yaml` (currently a plaintext
placeholder) is never read and the sops-nix module is completely inert.

To enable:

```bash
mkdir -p ~/.config/sops/age
nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
nix run nixpkgs#age -- -y ~/.config/sops/age/keys.txt   # public key
```

Put the public key in `.sops.yaml`, then `sops secrets/secrets.yaml` and add
`git_ssh_key` / `git_ssh_key_work`. Finally set `features.sops = true` — that
also activates the `github-personal` / `github-work` SSH match blocks in
`home/tools/git.nix`.

> On macOS the `sops` CLI defaults to `~/Library/Application Support/sops/age/keys.txt`,
> which is **not** where sops-nix looks. `home/default.nix` pins `SOPS_AGE_KEY_FILE`
> to `~/.config/sops/age/keys.txt` for both.

---

## Mosaic devShells — nothing nix-related inside the repos

Every Mosaic repo used to carry its own `flake.nix`, `flake.lock` and `.envrc`,
staged-but-never-committed (a git-backed flake is invisible to Nix unless it is
in the index). One `git commit -a` on a feature branch would have shipped them.
They now live here instead:

- `hosts/mosaic/flake.nix` — one flake, one lock. `devShells.<system>.mosaic-<repo>`
  is what direnv loads; `packages.<system>.mosaic-<repo>-services` is that
  repo's process-compose stack (postgres/redis/kafka/app), on PATH inside the
  shell as `services` (`services -t` for the TUI). State stays in the
  checkout's `./.data`, as before.
- `hosts/mosaic/envrc` — the ONE `.envrc`, symlinked into every Mosaic dev root
  (`home.nix` → `devDirs`) and whitelisted in direnv.toml. It works out which
  worktree you entered from direnv's directory stack, asks git for that
  worktree's toplevel, maps it to its repo via the remote URL, `cd`s into the
  worktree, pulls that repo's secrets from 1Password, then
  `use flake path:<this dir>#mosaic-<repo>` (the flake path is resolved from
  the symlink, nothing hardcodes where nixac lives).
- `hosts/mosaic/direnv-siblings.zsh` — direnv does not reload when you move between
  two directories under the same `.envrc`. The hook deletes the marker file
  the envrc watches whenever the worktree changes, which forces the reload.
  The header comment in `hosts/mosaic/envrc` has the full mechanism.

### Repos are bare clones; every branch is a worktree

```
~/dev/mosaic/
├── .envrc                          → hosts/mosaic/envrc
└── mosaic-rails-api/
    ├── .bare/                      the repository (bare)
    ├── .git                        "gitdir: ./.bare" — the container answers
    │                               git commands: worktree list/add, fetch, branch
    ├── party/                      one worktree per branch, named after it
    └── AI-123-some-feature/        (`/` in a branch name becomes `-`)
```

- `wt switch -c AI-123` (worktrunk, configured in `home/tools/gh.nix` with its
  bare-repository path template) creates `<repo>/AI-123` and cds there;
  `wt switch ^` is the default branch, `wt remove` drops a merged branch's
  worktree. Plain git works too: `git -C ~/dev/mosaic/<repo> worktree add AI-123`.
- Per-repo excludes (`.direnv/`, `.data/`, `result`) live in `.bare/info/exclude`
  and apply to every worktree. `bundle install` / `npm install` are per
  worktree, so is `./.data` — two worktrees never share a database.
- The container directory itself has no work tree, so cd-ing into it loads
  nothing; the shell appears once you are inside a branch directory.
- `git.work.dirs` in `hosts/mosaic/default.nix` lists every dev root; each gets
  the work identity and the work SSH key via `includeIf gitdir:` — that covers
  `.bare/worktrees/<name>` gitdirs too. Without it a `github.com` remote is
  reached with the personal key and answers "Repository not found".
- `mosaic-web` has remote branches that differ only in case (`WEB-20134` /
  `web-20134`, `feat/AI-542…` / `feat/ai-542…`), which the `files` ref backend
  cannot store on APFS. Its `remote.origin.fetch` carries two negative
  refspecs excluding the lowercase twins so `git fetch` exits cleanly.

Adding a repo: a module in `hosts/mosaic/devShells/`, one import line in
`hosts/mosaic/flake.nix`, and a `case` arm in `hosts/mosaic/envrc` if it needs secrets.
Adding a worktree: nothing — any directory under `~/dev/mosaic` whose remote is
a known repo gets that repo's shell.

## Gotchas worth remembering

- **Flakes ignore untracked files.** A new file that isn't `git add`-ed shows up
  as `flake output attribute 'darwinConfigurations.mosaic' does not exist`.
  Both scripts run `git add -N .` first.
- **Official Nix, not Determinate — and the installer barely matters.**
  nix-darwin owns which Nix the daemon runs (`nix.package`), so switching to Lix
  later is one declarative line plus a rebuild, no reinstall. Determinate is the
  one real fork in the road: it manages `/etc/nix/nix.conf` itself and needs
  `nix.enable = false` (or its module's `determinateNix.enable = true`), which
  makes all of `darwin/nix-settings.nix` dead code — settings move to
  `determinateNix.customSettings`, and `nix.gc` / `nix.optimise` /
  `nix.linux-builder` / `nix.package` have no equivalent. Its upside is handling
  macOS-upgrade breakage better; the trade wasn't worth losing declarative Nix
  config here.
- **Activation order.** Homebrew runs *before* Home Manager. A brew failure
  blocks `~/.zshrc`, ssh config and sops secrets from ever landing — the symptom
  is zsh's new-user wizard on a fresh shell.
- **Homebrew ≥6 tap trust** lives in `~/.homebrew/trust.json` and `brew bundle`
  rewrites it, so a manual `brew trust` is wiped. Tap-level `trusted = true`
  (as in `darwin/homebrew.nix`) is the only durable form.
- **Work repos need no special clone URL.** `~/dev/mosaic/**` gets the work
  identity *and* the work SSH key from one `includeIf`, because
  `core.sshCommand` is set inside it. `includeIf gitdir:` is already active
  during `git clone` — git creates `.git` before it fetches, so the condition
  matches when the connection is made. Clone plain
  `git@github.com:org/repo.git` into `~/dev/mosaic/` and both halves are right.
  The `github-work` host alias still exists and still works; it is now optional.
- **Git config is a writable wrapper.** `home/tools/git.nix` replaces the
  read-only store symlink at `~/.config/git/config` with a file that `[include]`s
  it, so tools running `git config --global` don't crash. Manual overrides go in
  `~/.config/git/config.local`.
- **Changing Zen policies wipes the profile.** Fine on a fresh machine, painful
  later.
- **Spotlight ignores symlinked apps.** `targets.darwin.copyApps` (not the
  `linkApps` default) is what makes Nix-installed apps like Zen appear in
  Spotlight, Raycast and Launchpad. With `linkApps` the app installs correctly
  and is simply invisible, which reads as "it didn't install".
- **Three-finger drag pushes macOS's Spaces swipe onto four fingers**, which is
  the gesture aerospace-swipe wants. `darwin/defaults.nix` sets
  `TrackpadFourFingerHorizSwipeGesture = 0` so macOS yields it to AeroSpace.
- **1Password + Zen: the native bridge needs no Nix wiring.** Zen reads
  `~/Library/Application Support/Mozilla/NativeMessagingHosts/` exactly like
  Firefox, and the 1Password desktop app already drops
  `com.1password.1password.json` there, whitelisting the extension GUID
  `{d634138d-c276-4fc8-924b-40a0ea21d284}`. Home Manager only manages
  `tridactyl.json` in that directory, so it leaves 1Password's manifest alone.
  What IS needed: the extension (declared in `home/apps/zen.nix`) plus a
  one-time authorisation in 1Password ▸ Settings ▸ Browser ▸ Add Browser.
  That step needs the browser code-signed (Zen is — Developer ID
  `9V5K9TP787`) and in an Applications folder; ours is under
  `~/Applications/Home Manager Apps/`.
- **`packageMode = "signed"` writes policies to a defaults domain**, not into
  the bundle: `~/Library/Preferences/app.zen-browser.zen.plist`. They are keyed
  by bundle ID, so a Zen installed anywhere else with the same ID picks up the
  same policies — which is what makes a Homebrew-cask fallback viable if
  1Password ever refuses the Home Manager path.
- **Work secrets live in 1Password, never in this repo.** `tools/onepassword.nix`
  installs the `op` CLI and defines an `op_export` direnv helper; a work repo's
  `.envrc` then does
  `op_export NPM_TASKFORCESH_TOKEN "op://<vault>/<item>/<field>"`.
  The `op://` refs are pointers, not secrets, so those `.envrc` files are safe
  to commit. Both Mosaic items keep their credentials as free text in the item
  Notes rather than as structured fields, so they use `op_notes_export` — which
  reads the note once and parses `KEY=value` lines out of it (tolerating the
  stray `export ` prefixes those notes mix in). It parses rather than `eval`s,
  since eval-ing a secret would run whatever a note happens to contain. sops (`tools/sops.nix`) stays reserved for *personal* secrets —
  putting work credentials in a personal dotfiles repo is the thing this avoids.
  One-time: 1Password ▸ Settings ▸ Developer ▸ "Integrate with 1Password CLI",
  then `op signin`, then `direnv allow` per repo.
- **Neovim LSPs come from PATH only.** Mason is disabled in
  `lazyvim/lua/config/lazy.lua`, so a language server needs BOTH the binary in
  `programs.neovim.extraPackages` AND its LazyVim extra in `lazyvim.json`.
  Either one alone silently does nothing.
- **`programs.neovim.withRuby` must stay false.** It builds a `neovim-ruby-env`
  in the store and puts it on `GEM_PATH` for every process neovim spawns.
  ruby-lsp inherits it, concludes the project bundle lives there, and dies with
  `Bundler::PermissionError` trying to write gems into the read-only Nix store.
  LazyVim uses no Ruby remote plugins, so nothing needs the provider.
- **Atuin's pty-proxy breaks any `ps`-based tmux detection.** `tools/atuin.nix`
  runs `atuin pty-proxy` (needed for the Ctrl-R tmux popup), so a pane's process
  tree is `atuin -> zsh -> nvim` and `ps -o comm= -t '#{pane_tty}'` reports only
  `atuin`. vim-tmux-navigator's stock `is_vim` check can therefore never match —
  no regex fixes it. `shell/tmux.nix` replaces those bindings with
  `if-shell -F '#{@pane-is-vim}'`, and the neovim side sets that pane option on
  `VimEnter`/`VimResume` and clears it on `VimLeave`/`VimSuspend`. Worth
  backporting to lumino, which has the same latent bug.
- **Nix-store PUA glyphs don't survive hand-editing.** Powerline separators and
  Nerd Font icons (U+E000–F8FF) get silently dropped when a config file is
  rewritten by hand — the `[]` pairs end up empty and starship renders with no
  separators at all. Copy such files byte-for-byte from lumino, or insert the
  glyphs by codepoint (`chr(0xF0E7)`). Verify with a cmap check against
  `/Library/Fonts/Nix Fonts/*/...JetBrainsMonoNerdFont-Regular.ttf`, not by eye.
- **Don't copy lumino's tmux status glyphs verbatim.** lumino uses emoji (🪟 ⚙️
  📁 🔎 🟅) that JetBrains Mono Nerd Font does not contain; nixac uses the Nerd
  Font equivalents so everything renders from one font.

### Known-good input revisions

`flake.lock` is regenerated on first build. If a fresh resolve breaks, these are
the revisions komashi is proven against:

```
nixpkgs       aca4d95fce4914b3892661bcb80b8087293536c6
home-manager  bf9ce9fec78f95f374e8dd3b503863a3ec128ebe
sops-nix      f1406619a3884cd5c47992a70b8b35c9c0fcb4c9
nix-darwin    15abb8c98f336cd8bd840d71059adebabe60bf04
zen-browser   12224626d0d1cead79603f19601666360c715379
```

```bash
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/aca4d95fce4914b3892661bcb80b8087293536c6
```

---

## Key bindings

### tmux (prefix `Ctrl+Space`)
| Key | Action |
|---|---|
| `prefix h` / `v` | Split horizontal / vertical |
| `Alt+h/j/k/l` | Resize panes |
| `Alt+1-5` | Switch tmux windows (why AeroSpace starts at workspace 6) |
| `Ctrl+g` | Session picker (sesh + fzf) |
| `prefix K` | Lazygit popup |
| `prefix F` | Yazi popup |

### AeroSpace (alt = Option)
| Key | Action |
|---|---|
| `Alt+h/j/k/l` | Focus window |
| `Alt+Shift+h/j/k/l` | Move window |
| `Alt+6-9` | Workspace 6-9 |
| `Alt+<letter>` | Named workspace (T=Terminal, B=Browser, I=IDE, O=Obsidian, S=Spotify…) |
| `Alt+[` / `Alt+]` | Cycle **non-empty** workspaces |
| `Alt+Shift+f` | Fullscreen |
| `Alt+Shift+;` | Service mode |
| 4-finger swipe | Switch workspace (3-finger is owned by macOS drag) |

### zsh
| Key | Action |
|---|---|
| `Ctrl+r` | Atuin history (in a tmux popup) |
| `Ctrl+y` | Accept autosuggestion |
| `Ctrl+g` | sesh picker outside tmux |

---

## What was deliberately left out of the komashi port

| Dropped | Why |
|---|---|
| kitty | Ghostty only |
| zathura | Television only, per request |
| Firefox module + cask | You manage Firefox yourself |
| docker-desktop, cursor, bitwarden casks | Work apps stay outside Nix |
| claude-code / opencode / codex / agent-sync | Parked in `home/agents/`, add later |
| Most macOS defaults | System Settings owns them; komashi's block is commented in `darwin/defaults.nix` |
| `modules/dev-shells` templates | `fnew`/`finit` point at `the-nix-way/dev-templates`; override with `$NIXAC_TEMPLATES` |

Nothing was deleted — parked modules are still in the tree, just not imported.
