# 1Password CLI + a direnv helper for pulling per-repo secrets.
#
# Work credentials (private npm registries, private gem sources, docker
# registry logins) are deliberately NOT stored in this repo — not even
# sops-encrypted. nixac is a personal dotfiles repo; the team already
# distributes these through 1Password, so 1Password stays the single source of
# truth and rotation happens there rather than here.
#
# A repo opts in from its own .envrc:
#
#   use flake
#   op_export NPM_TASKFORCESH_TOKEN "op://<vault>/<item>/<field>"
#
# In an interactive shell direnv keeps the loaded environment, so the read
# happens on first cd (and after .envrc changes). `direnv exec`, editors and
# agents like Claude Code re-evaluate the .envrc for EVERY command instead, in
# shells with no tty — and 1Password ties a CLI approval to the tty, so without
# a cache each of those reads is a fresh approval prompt. The helpers therefore
# keep what they read on disk for 12h; see _op_read_cached below.
#
# One-time setup, in this order:
#   1. 1Password app ▸ Settings ▸ Developer ▸ "Integrate with 1Password CLI"
#      (this is what lets `op` unlock via Touch ID instead of a password prompt)
#   2. op signin
#   3. direnv allow   in each repo
{ pkgs, ... }:
let
  # By store path: whichever stat is first on PATH (BSD or GNU) decides what
  # its flags mean, and the cache's age check can't be left to chance.
  coreutils = "${pkgs.coreutils}/bin";
  flock = "${pkgs.flock}/bin/flock";
in
{
  home.packages = [ pkgs._1password-cli ];

  programs.direnv.stdlib = ''
    # _op_read_cached "op://vault/item/field"
    #
    # `op read`, remembered on disk: one file per reference (named by its
    # hash) under ~/.cache/direnv/op, dir 0700 and files 0600, reused for 12h
    # after the read that fetched it — never extended by use. Set
    # OP_CACHE_TTL_SECONDS to change the 12h. After a credential rotates in
    # 1Password:   rm -rf ~/.cache/direnv/op
    #
    # A miss takes a lock first, so shells that start together on a cold cache
    # queue behind ONE prompt and then read what it fetched. A failed read
    # (prompt declined or timed out, 1Password signed out) is remembered for
    # 5 minutes, so that same queue doesn't re-ask one shell after another.
    _op_read_cached() {
      local ref="''$1"
      local dir="''${XDG_CACHE_HOME:-''$HOME/.cache}/direnv/op"
      local ttl="''${OP_CACHE_TTL_SECONDS:-43200}"
      local file
      file="$(printf '%s' "''$ref" | ${coreutils}/sha256sum)"
      file="''$dir/''${file%% *}"

      if _op_cache_fresh "''$file" "''$ttl" && cat "''$file"; then
        return 0
      fi

      mkdir -p "''$dir" && chmod 700 "''$dir" || return 1

      # The subshell holds the lock on fd 9, and it is released however the
      # subshell ends.
      (
        if ! ${flock} -w 120 9; then
          log_error "op: gave up after 2 min waiting for another shell's 1Password prompt"
          exit 1
        fi

        # Fetched by whoever held the lock before us?
        if _op_cache_fresh "''$file" "''$ttl" && cat "''$file"; then
          exit 0
        fi
        if _op_cache_fresh "''$file.failed" 300; then
          log_error "op: not asking 1Password again yet — reading ''$ref failed under 5 min ago"
          log_error "  to retry now: rm -f ''$file.failed"
          exit 1
        fi

        # 9>&- because op can start its background daemon, which would
        # otherwise inherit fd 9 and hold the lock for as long as it runs.
        if val="$(op read --no-newline "''$ref" 9>&- 2>/dev/null)" && [ -n "''$val" ]; then
          # mktemp creates the file 0600; the mv makes the write atomic for
          # the lock-free fast path above.
          if tmp="$(mktemp "''$file.XXXXXX")"; then
            { printf '%s' "''$val" > "''$tmp" && mv -f "''$tmp" "''$file"; } || rm -f "''$tmp"
          fi
          rm -f "''$file.failed"
          printf '%s' "''$val"
        else
          : > "''$file.failed"
          exit 1
        fi
      ) 9> "''$dir/.lock"
    }

    # _op_cache_fresh FILE MAX_AGE_SECONDS — FILE exists and is younger than that.
    _op_cache_fresh() {
      local mtime
      mtime="$(${coreutils}/stat -c %Y -- "''$1" 2>/dev/null)" || return 1
      [ "$(( $(${coreutils}/date +%s) - mtime ))" -lt "''$2" ]
    }

    # op_export VAR "op://vault/item/field"
    #
    # Export VAR from 1Password. Deliberately non-fatal: a missing token should
    # degrade to the devShell's own "token not set" warning, which explains what
    # breaks and why, rather than blocking `cd` into the repo entirely. You can
    # still lint, read code and run anything that doesn't hit the private
    # registry while signed out.
    op_export() {
      local var="''$1" ref="''$2"

      # An already-exported value wins. Lets you override with a scratch token
      # without editing .envrc, and keeps CI (which injects real env vars)
      # from needing 1Password at all.
      if [ -n "''${!var:-}" ]; then
        return 0
      fi

      if ! has op; then
        log_error "op_export: 1Password CLI not found — is the nixac generation active?"
        return 0
      fi

      local val
      if val="$(_op_read_cached "''$ref")" && [ -n "''$val" ]; then
        export "''$var=''$val"
      else
        log_error "op_export: could not read ''$var from ''$ref"
        log_error "  try: op signin   (and enable 1Password ▸ Developer ▸ CLI integration)"
      fi
    }

    # op_export_multi "op://vault/item" VAR1=field1 VAR2=field2 ...
    #
    # Same, for several STRUCTURED fields of one item — one unlock prompt and
    # one op invocation per variable, but all against the same item.
    op_export_multi() {
      local item="''$1"; shift
      local pair var field
      for pair in "''$@"; do
        var="''${pair%%=*}"
        field="''${pair#*=}"
        op_export "''$var" "''$item/''$field"
      done
    }

    # op_notes_export "op://vault/item/notesPlain" VAR1 VAR2 ...
    #
    # For items that keep credentials as free text in the Notes field instead
    # of as structured fields — a dotenv-ish blob of KEY=value lines. Both of
    # the Mosaic items are like this, and they aren't even internally
    # consistent: some lines carry a leading `export`, some don't.
    #
    # Reads the note ONCE (one unlock, one op call) and exports only the
    # variables you name — and doesn't read it at all when every one of them
    # is already set. Deliberately parses rather than `eval`s the blob:
    # eval-ing a secret would execute whatever a note happens to contain.
    op_notes_export() {
      local ref="''$1"; shift
      local blob var val missing=""

      for var in "''$@"; do
        [ -n "''${!var:-}" ] || missing=1
      done
      if [ -z "''$missing" ]; then
        return 0
      fi

      if ! has op; then
        log_error "op_notes_export: 1Password CLI not found — is the nixac generation active?"
        return 0
      fi

      # tr -d '\r': notes edited on Windows/web come back CRLF, and a trailing
      # CR silently corrupts every value.
      if ! blob="$(_op_read_cached "''$ref" | tr -d '\r')" || [ -z "''$blob" ]; then
        log_error "op_notes_export: could not read ''$ref"
        log_error "  try: op signin   (and enable 1Password ▸ Developer ▸ CLI integration)"
        return 0
      fi

      for var in "''$@"; do
        # An already-exported value wins, same as op_export.
        if [ -n "''${!var:-}" ]; then
          continue
        fi
        val="$(printf '%s\n' "''$blob" \
          | sed -n -E "s/^[[:space:]]*(export[[:space:]]+)?''${var}=[[:space:]]*//p" \
          | head -1)"
        # Strip one layer of surrounding quotes if the note used them.
        val="''${val%\"}"; val="''${val#\"}"
        val="''${val%\'}"; val="''${val#\'}"
        if [ -n "''$val" ]; then
          export "''$var=''$val"
        else
          log_error "op_notes_export: ''$var not found in ''$ref"
        fi
      done
    }
  '';
}
