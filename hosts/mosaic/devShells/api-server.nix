# mosaic-api-server — Rails 8 / Ruby 3.4 development environment + local services
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      mosaicLib,
      ...
    }:
    let
      # `services` runs OUTSIDE the devShell, so these processes inherit none
      # of its PATH or BUNDLE_PATH — a bare `bundle exec` there finds either no
      # bundler at all or the wrong gem home. This wrapper reproduces the two
      # things bundler actually needs, and nothing else.
      appProcess =
        name: cmd:
        pkgs.writeShellScript name ''
          export PATH="${
            lib.makeBinPath [
              pkgs.ruby_3_4
              pkgs.bundler
              pkgs.postgresql_17
              pkgs.git
            ]
          }:$PATH"
          export BUNDLE_PATH="$PWD/vendor/bundle"
          # Isolated for the same reason as the devShell below: a stale gem
          # in ~/.local/share/gem must not shadow ruby's own default gems.
          export GEM_HOME="$PWD/.gem"
          export GEM_PATH="$GEM_HOME"

          # Fail with the actual cause rather than bundler's "could not find
          # gem" wall of text, which reads like a Gemfile problem.
          if [ ! -d "$BUNDLE_PATH" ]; then
            echo "$BUNDLE_PATH does not exist — run 'bundle install' first." >&2
            exit 1
          fi

          exec ${cmd}
        '';
    in
    {
      # ── `services` ────────────────────────────────────────────────────────
      # PostgreSQL and Redis run as ORDINARY LOCAL PROCESSES — no Docker, no
      # VM. On macOS that removes the whole Linux-VM layer docker-compose
      # needs, so startup is a second or two and there's nothing to install
      # beyond Nix itself.
      #
      # State lives in ./.data (gitignored), so `rm -rf .data` is a full
      # reset and two checkouts of this repo never share a database.
      #
      # Ports match example.env rather than docker-compose.yml: the compose
      # file shifts them (15432/16379) to avoid clashing with host services,
      # but nothing is competing for them here.
      process-compose."mosaic-api-server-services" = {
        imports = [ inputs.services-flake.processComposeModules.default ];

        # The HTTP API stays on, so `process-compose attach` and
        # `process-compose down` can reach a detached run — but NOT on
        # process-compose's default 8080, which is a popular port and was in
        # fact already taken on a dev machine, making `services` die with
        # "bind: address already in use" before any service started.
        cli.options.no-server = false;
        cli.options.port = 8188;

        # TUI off by default. It needs a real terminal, so with it on the
        # default the command fails outright anywhere without one — a CI
        # step, a script, an editor task, an agent shell — with
        # "TUI startup error: terminal entry not found: term not set".
        # Pass `-t` to get the dashboard back:  services -t
        #
        # This is the PC_DISABLE_TUI env var rather than a CLI flag because
        # the pinned process-compose-flake has no cli.options.tui, and an
        # env default still loses to an explicit -t on the command line.
        cli.environment.PC_DISABLE_TUI = true;

        services.postgres."pg" = {
          enable = true;

          # NOTE: docker-compose.yml pins postgres:13-alpine, but 13 reached
          # end-of-life in Nov 2025 and is gone from nixpkgs — 14 is the
          # oldest still packaged. 17 is used here deliberately (it is also
          # what mosaic-ai-server runs, so there's one version to think
          # about). If a partitioning or pg_party difference ever bites,
          # dropping to pkgs.postgresql_14 is a one-line change.
          package = pkgs.postgresql_17;

          listen_addresses = "127.0.0.1";
          port = 5432;
          dataDir = "./.data/pg";

          # services-flake defaults the superuser to $USER. example.env's
          # DATABASE_URL is postgres://postgres:password@localhost/... , so
          # without this every connection fails with
          #   FATAL: role "postgres" does not exist
          # The password in that URL is ignored — local connections are
          # trust-authenticated, which is fine for a dev database bound to
          # 127.0.0.1 only.
          superuser = "postgres";

          # Carried over from docker-compose.yml's
          #   command: -c max_locks_per_transaction=1024
          # pg_party creates a lot of partitions, and the default (64) is
          # not enough to migrate or truncate them in one transaction.
          settings.max_locks_per_transaction = 1024;

          initialDatabases = [
            { name = "api_server_development"; }
            { name = "api_server_development_test"; }
          ];
        };

        services.redis."redis" = {
          enable = true;
          bind = "127.0.0.1";

          # Not configurable in practice: config/initializers/sidekiq.rb
          # builds its URL as "redis://#{host}:6379/#{db}" with the port
          # hardcoded, so SIDEKIQ_REDIS_HOST can move the host but never the
          # port. 6379 it is.
          port = 6379;
          dataDir = "./.data/redis";
        };

        # ── The app itself ─────────────────────────────────────
        # docker-compose.yml ran four containers: postgres, redis, app and
        # sidekiq. These two make `services` a complete replacement for it.
        #
        # restart = "no" is deliberate. Both processes need gems, and on a
        # fresh checkout there are none — restarting on failure would bury
        # the one line that says so under an endless crash loop.
        settings.processes = {
          app = {
            # Interpolated, not passed as a derivation: `command` runs a
            # bare derivation through lib.getExe, which appends /bin/<name>
            # to what is already a plain script file and dies with
            # "Not a directory" (exit 126).
            command = "${appProcess "api-server-app" "bundle exec rails server -b 127.0.0.1 -p 3000"}";
            depends_on = {
              pg.condition = "process_healthy";
              redis.condition = "process_healthy";
            };
            availability.restart = "no";
          };

          sidekiq = {
            command = "${appProcess "api-server-sidekiq" "bundle exec sidekiq -C config/sidekiq.yml"}";
            depends_on = {
              pg.condition = "process_healthy";
              redis.condition = "process_healthy";
            };
            availability.restart = "no";
          };
        };
      };

      # ── direnv (`use flake …#mosaic-api-server`) ────────────────────────
      devShells."mosaic-api-server" = pkgs.mkShell {
        name = "mosaic-api-server";

        packages =
          with pkgs;
          [
            # ── Language runtime ──────────────────────────────────────────
            # nixpkgs ruby_3_4 is exactly 3.4.9, which is what .ruby-version
            # pins and what the Gemfile enforces via
            #   ruby File.read(".ruby-version").strip
            # so bundler will not complain about a version mismatch.
            ruby_3_4

            # Gemfile.lock says `BUNDLED WITH 2.7.2`, but ruby_3_4 only ships
            # bundler 2.6.9 as a default gem — so a bare `bundle` aborts with
            # "Activating bundler (~> 2.7) failed". nixpkgs' standalone
            # bundler is exactly 2.7.2. hiPrio so it wins the PATH collision
            # against ruby's bundled copy.
            (lib.hiPrio bundler)

            # ── Service clients ───────────────────────────────────────────
            # The servers themselves come from `services`; these are the CLIs,
            # plus libpq in case a gem ever builds pg from source.
            # Gemfile.lock ships precompiled pg + nokogiri for arm64-darwin,
            # so a normal `bundle install` does no native database build.
            postgresql_17
            redis

            # ── Ruby tooling ──────────────────────────────────────────────
            # Also on PATH for editors: neovim resolves LSPs from PATH.
            ruby-lsp

            # rubocop and rubyPackages_3_4.standard are deliberately NOT here.
            # Anything in `packages` lands on GEM_PATH, and rubygems prefers a
            # GEM_PATH gem over one in vendor/bundle — so nixpkgs' rubocop
            # 1.80.2 was being loaded to read the bundled standard 1.56.0's
            # config, and every lint run died with
            #   unrecognized cop or department Lint/DataDefineOverride
            #   found in .../standard-1.56.0/config/base.yml
            # `bundle exec` does not isolate this; the paths are baked into
            # the nix ruby wrapper, so clearing GEM_PATH does not help either.
            #
            # Nothing is lost. Gemfile.lock pins rubocop 1.88.2 and standard
            # 1.56.0, `make lint` runs ./bin/standardrb and check_complexity
            # runs `bundle exec rubocop` — all three from the bundle, which is
            # also what CI lints with. $PWD/bin is on PATH below, so editors
            # resolve the same binstubs. (devShells/rails-api.nix documents the
            # same trap from the other direction.)

            # ── Build deps for native gem extensions ──────────────────────
            # msgpack, racc, prometheus_exporter and pg_party compile C.
            pkg-config
            libyaml
            openssl
            zlib

            # ── General ───────────────────────────────────────────────────
            gnumake # the repo drives lint/complexity through the Makefile
            git
            curl
            jq
          ]
          ++ [
            # `services` — the process-compose stack above, run from the repo root.
            (mosaicLib.servicesWrapper "mosaic-api-server-services")
          ];

        shellHook = ''
          # Keep gems inside the repo. vendor/bundle is already in
          # .gitignore, and this keeps the project's gems out of any global
          # GEM_HOME.
          export BUNDLE_PATH="$PWD/vendor/bundle"
          # Pin the gem SEARCH path to this project too. Without this
          # RubyGems also searches ~/.local/share/gem/ruby/3.4.0, where a
          # stale user-installed gem can shadow ruby's own default copy. In
          # practice io-console 0.9.2 does, with a native extension linked
          # against a different ruby, so `require "io/console"` raises
          #   LoadError: linked to incompatible .../libruby-3.4.9.dylib
          # rubocop's pacman formatter calls $stdout.winsize, which comes
          # from io/console — so `make lint` and `make lint_changes` both
          # died with "undefined method 'winsize' for an instance of IO"
          # AFTER reporting no offenses, which reads like a lint failure and
          # is not one.
          #
          # Safe to isolate: bundler is a PATH binary carrying its own lib
          # dir, and ruby-lsp resolves the project's gems through bundler
          # rather than through GEM_PATH.
          export GEM_HOME="$PWD/.gem"
          export GEM_PATH="$GEM_HOME"

          # The repo ships binstubs (bin/rails, bin/rspec, bin/standardrb…).
          # Putting them first means `standardrb` and friends resolve to the
          # project's bundled versions rather than the ones above.
          export PATH="$PWD/bin:$PATH"

          echo ""
          echo "  mosaic-api-server  ·  ruby $(ruby -e 'print RUBY_VERSION')  ·  $(psql --version | cut -d' ' -f3 | xargs echo psql)"
          echo ""

          # This warning is only meaningful outside direnv. Under direnv the
          # .envrc fetches the token from 1Password BEFORE `use flake` (the
          # ordering there is load-bearing — see the comment in the envrc),
          # and op_notes_export reports its own failures.
          if [ -z "''${DIRENV_IN_ENVRC:-}" ] && [ -z "''${BUNDLE_ENTERPRISE__CONTRIBSYS__COM:-}" ]; then
            echo "  ! BUNDLE_ENTERPRISE__CONTRIBSYS__COM is not set."
            echo "    sidekiq-pro will fail to install (401 from enterprise.contribsys.com)."
            echo "    Inside direnv this is fetched from 1Password automatically."
            echo ""
          fi

          if [ ! -f .env ]; then
            echo "  ! No .env — the Makefile and dotenv-rails both expect one:"
            echo "      cp example.env .env"
            echo ""
          fi

          cat <<'EOT'
            bundle install                         install gems into vendor/bundle
            bin/rails db:create db:migrate         set up the database
            services                               EVERYTHING: postgres :5432, redis :6379,
                                                   rails :3000, sidekiq — no Docker
            services -t                            same, with the dashboard TUI
            bin/rspec                              tests
            make lint                              standardrb --fix
            make check_complexity                  rubocop metrics

          Service state lives in ./.data — `rm -rf .data` is a clean reset.
          If a service will not start and the log names another PID holding
          .data, a previous run was killed hard and its children outlived
          it. `rm -rf .data` will NOT help — those are live processes:
            lsof -nP -iTCP:5432 -iTCP:6379 -iTCP:3000 -sTCP:LISTEN
          app and sidekiq need gems, so run `bundle install` before the
          first `services` or those two will exit straight away.

          ruby-lsp resolves the project's gems through bundler, so it only
          works once `bundle install` has run — and it needs BUNDLE_PATH,
          which is set here. Launch nvim from inside this shell (direnv does
          that automatically on cd) rather than from a plain terminal.
          EOT
          echo ""
        '';
      };
    };
}
