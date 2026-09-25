# Git — identity split + delta pager. Ported from lumino's modules/shell/git.nix
# with the YAML-driven plumbing replaced by hosts/mosaic/default.nix.
#
# Identity: host.git.userName/userEmail is the default; host.git.work adds an
# includeIf per work.dirs entry so repos there automatically use the work identity. Verify
# with `git config user.email` inside a repo.
{
  config,
  lib,
  host,
  ...
}:
let
  inherit (host) git;
  workEnabled = git.work.enable or false;

  # profile name -> ssh config host alias
  profiles = {
    personal = "github-personal";
  }
  // lib.optionalAttrs workEnabled { work = "github-work"; };

  sshCfg = git.ssh or { };

  # A profile is usable if it names a key file, or names a sops secret while
  # sops is enabled. Explicit identityFile always wins over sops.
  resolveKey =
    name:
    let
      c = sshCfg.${name} or { };
      file = c.identityFile or null;
      secret = c.sopsSecret or null;
    in
    if file != null then
      file
    else if secret != null && host.features.sops then
      config.sops.secrets.${secret}.path
    else
      null;

  usable = lib.filterAttrs (name: _: resolveKey name != null) profiles;

  # The work profile's key, if it resolves — used both for the ssh host alias
  # and for the directory-scoped core.sshCommand below.
  workKey = if workEnabled then resolveKey "work" else null;

  # programs.ssh.settings renders keys straight through as OpenSSH directives,
  # so these use upstream names (HostName, not hostname). programs.ssh.matchBlocks
  # is a deprecated alias for the same option.
  hostBlocks = lib.mapAttrs' (
    name: alias:
    lib.nameValuePair alias {
      HostName = "github.com";
      User = "git";
      IdentityFile = resolveKey name;
      IdentitiesOnly = true;
    }
  ) usable;

  # sops entries only for profiles that fell through to the sops branch.
  sopsSecrets =
    lib.mapAttrs' (name: _: lib.nameValuePair (sshCfg.${name}.sopsSecret) { mode = "0600"; })
      (
        lib.filterAttrs (
          name: _:
          (sshCfg.${name}.identityFile or null) == null
          && (sshCfg.${name}.sopsSecret or null) != null
          && host.features.sops
        ) profiles
      );
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = git.userName;
        email = git.userEmail;
      };

      # delta — syntax-highlighted diffs, installed via home/default.nix packages
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = false;
        line-numbers = true;
        hyperlinks = true;
        syntax-theme = "Catppuccin Mocha";
      };

      merge.conflictstyle = "zdiff3";
      diff.colorMoved = "default";
    };

    # Everything under any git.work.dirs entry gets the work identity AND the work SSH key,
    # with no special clone URL. `includeIf gitdir:` is active during `git clone`
    # too — git creates .git before it fetches, so the condition already matches
    # when the connection is made (verified empirically, not assumed).
    #
    # core.sshCommand overrides ~/.ssh/config for these repos, so a plain
    # `git clone git@github.com:org/repo.git ~/dev/mosaic/repo` uses the work key.
    # The github-work alias still works and is now optional.
    #
    # For a bare clone with linked worktrees (<root>/<repo>/.bare + <root>/<repo>/<branch>)
    # gitdir is <root>/<repo>/.bare/worktrees/<name>, still under the root, so
    # the same condition covers the whole worktree layout.
    includes = lib.optionals workEnabled (
      map (dir: {
        condition = "gitdir:${dir}**";
        contents = {
          user = {
            name = git.work.userName;
            email = git.work.userEmail;
          };
        }
        // lib.optionalAttrs (workKey != null) {
          core.sshCommand = "ssh -i '${workKey}' -o IdentitiesOnly=yes";
        };
      }) git.work.dirs
    );
  };

  # home-manager writes ~/.config/git/config; the activation script below then
  # REPLACES it with a writable wrapper. Without force = true that guarantees a
  # collision on every subsequent switch: HM finds a real file where it wants a
  # symlink, tries to back it up to config.bak, finds last switch's config.bak
  # already there, and aborts the whole activation with
  #   "Existing file '~/.config/git/config.bak' would be clobbered"
  # — which silently strands every other home change too.
  #
  # force = true makes HM skip the collision check for this one path
  # ("Skipping collision check for ..."), so no .bak is ever produced for a
  # file we intend to overwrite anyway.
  xdg.configFile."git/config".force = true;

  # macOS: replace the read-only Nix-store symlink at ~/.config/git/config with
  # a writable wrapper that [include]s it. Tools that run `git config --global`
  # at startup (codegen, some IDE integrations) crash against the immutable
  # symlink. Manual overrides persist in ~/.config/git/config.local.
  home.activation.writableGitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    gc="$HOME/.config/git/config"
    local_gc="$HOME/.config/git/config.local"
    if [ -L "$gc" ]; then
      nix_target="$(readlink "$gc")"
      $DRY_RUN_CMD rm "$gc"
      $DRY_RUN_CMD touch "$local_gc"
      cat > "$gc" << EOF
    # Auto-generated by nixac home/tools/git.nix — DO NOT EDIT directly.
    # Writable wrapper so tools can run \`git config --global\`.
    # Nix-managed settings are included from the store path below.
    # Persistent manual overrides go in ~/.config/git/config.local.
    [include]
    	path = $nix_target
    [include]
    	path = $local_gc
    EOF
    fi
  '';

  # ── SSH identities ───────────────────────────────────────────────────────
  # Writes ~/.ssh/config host aliases so each GitHub identity uses its own key.
  #
  # Deliberately NOT gated on features.sops: where a key is stored (a plain
  # file vs. an encrypted secret) is independent of whether nixac manages the
  # ssh config. Gating them together meant that with sops off — the default —
  # nothing wrote ~/.ssh/config at all.
  #
  # Per profile, hosts/<host>.nix picks the source:
  #   identityFile = "<path>"  -> use that key file directly
  #   identityFile = null      -> decrypt sopsSecret via sops-nix
  # A profile resolving to neither is simply skipped.
  #
  # NOTE ON CLONING: the includeIf above switches your *identity* (name/email)
  # by directory; these aliases switch the *key* by URL. They are independent.
  # Clone work repos as  git@github-work:org/repo.git  into one of git.work.dirs
  # to get both.
  programs.ssh = lib.mkIf (hostBlocks != { }) {
    enable = true;

    # home-manager's built-in "*" defaults are deprecated and warn on every
    # build; opt out and own them here instead.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        # macOS: load the key into ssh-agent and remember its passphrase in the
        # login Keychain, so it is typed once per boot rather than once per push.
        AddKeysToAgent = "yes";
        UseKeychain = true;

        # The rest are home-manager's former defaults, kept explicitly now that
        # enableDefaultConfig no longer supplies them.
        ForwardAgent = false;
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    }
    // hostBlocks;
  };

  # Only declare sops secrets for profiles that actually resolve to sops.
  sops.secrets = lib.mkIf (sopsSecrets != { }) sopsSecrets;
}
