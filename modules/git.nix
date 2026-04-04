# Git with multi-identity support and optional sops SSH key decryption.
#
# To enable sops SSH keys:
#   1. Add your SSH private key to secrets/secrets.yaml under key "git_ssh_key"
#   2. Encrypt with: sops secrets/secrets.yaml
#   3. Set enableSopsSSH = true below
#
# Without sops, git works normally — just no auto-decrypted SSH keys.
{ config, lib, pkgs, ... }:
let
  # ── Toggle this to enable sops-managed SSH keys ──────────────────────
  enableSopsSSH = true;

  secretsFile = ../secrets/secrets.yaml;
  secretsReady = enableSopsSSH && builtins.pathExists secretsFile;
in
{
  programs.git = {
    enable = true;

    includes = [
      # Work profile — auto-activates for repos under ~/dev/intuit/
      {
        condition = "gitdir:~/dev/intuit/**";
        contents = {
          user = {
            name = "spadia";
            email = "shyam_padia@intuit.com";
          };
        };
      }
    ];

    settings = {
      user = {
        name = "crizzy9";
        email = "shyampadia@live.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  # SSH config — only when sops secrets are ready
  programs.ssh = lib.mkIf secretsReady {
    enable = true;
    matchBlocks = {
      "github-personal" = {
        hostname = "github.com";
        identityFile = config.sops.secrets.git_ssh_key.path;
        identitiesOnly = true;
      };
      "github.intuit.com" = {
        hostname = "github.intuit.com";
        identityFile = config.sops.secrets.git_ssh_key_work.path;
        identitiesOnly = true;
      };
    };
  };

  # Decrypt SSH keys via sops
  sops.secrets = lib.mkIf secretsReady {
    git_ssh_key = { mode = "0600"; };
    git_ssh_key_work = { mode = "0600"; };
  };

  # Replace HM's read-only symlink with a writable wrapper so tools
  # that run `git config --global` (codegen, etc.) don't crash.
  home.activation.writableGitConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      gc="$HOME/.config/git/config"
      local_gc="$HOME/.config/git/config.local"
      if [ -L "$gc" ]; then
        nix_target="$(readlink "$gc")"
        $DRY_RUN_CMD rm "$gc"
        $DRY_RUN_CMD touch "$local_gc"
        cat > "$gc" << EOF
# Auto-generated — writable wrapper for git config --global
[include]
	path = $nix_target
[include]
	path = $local_gc
EOF
      fi
    '';
}
