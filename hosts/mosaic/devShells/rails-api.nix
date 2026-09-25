# mosaic-rails-api — Rails 8 / Ruby 4.0 development environment + local services
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
      # of its PATH, BUNDLE_PATH or GEM_HOME. This reproduces exactly the three
      # things bundler needs, including the project-local bundler 2.7.2 the
      # shellHook installs into ./.gem (ruby_4_0 ships 4.0.16 as a default
      # gem, which bin/bundle refuses).
      appProcess =
        name: cmd:
        pkgs.writeShellScript name ''
          export PATH="$PWD/.gem/bin:${
            lib.makeBinPath [
              pkgs.ruby_4_0
              pkgs.postgresql_16
              pkgs.git
            ]
          }:$PATH"
          export BUNDLE_PATH="$PWD/vendor/bundle"
          export GEM_HOME="$PWD/.gem"
          # Isolated for the same reason as the devShell below: nixpkgs'
          # ruby-3.4 gem dirs must not leak into this ruby-4.0.6 process.
          export GEM_PATH="$GEM_HOME"
          # ...and drop RUBYLIB entirely. GEM_PATH is not enough on its own:
          # pkgs.ruby-lsp and pkgs.rubocop are ruby-3.4 builds and nix puts
          # their lib dirs straight into RUBYLIB, which lands on $LOAD_PATH
          # ahead of everything and bypasses rubygems completely — so
          # `require "json"` resolves to ruby3.4-json inside this ruby-4.0.6
          # shell and dies with
          #   LoadError: linked to incompatible .../libruby-3.4.9.dylib
          # Safe to clear: both are PATH binaries whose nix wrappers set
          # their own RUBYLIB at invocation, so editors still resolve them.
          unset RUBYLIB

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
      # Replaces `docker-compose up -d postgres redis app sidekiq`.
      # PostgreSQL and Redis run as ORDINARY LOCAL PROCESSES — no Docker, no
      # VM, which on macOS removes the whole Linux-VM layer and cuts startup
      # to a second or two.
      #
      # State lives in ./.data (gitignored), so `rm -rf .data` is a full
      # reset and two checkouts never share a database.
      process-compose."mosaic-rails-api-services" = {
        imports = [ inputs.services-flake.processComposeModules.default ];

        # The HTTP API stays on so `process-compose attach` can reach a
        # detached run — but NOT on process-compose's default 8080, which is
        # a popular port and was already taken on a dev machine, making
        # `services` die with "bind: address already in use" before any
        # service started. 8189 here, 8188 in mosaic-api-server, 8187 in
        # mosaic-chat-bots, so a stray detached run in one repo cannot be
        # mistaken for the other's. The SERVICES still cannot co-run with
        # api-server: both repos' .env files put postgres on 5432, redis on
        # 6379 and rails on 3000, so bring one stack down before starting the
        # other.
        cli.options.no-server = false;
        cli.options.port = 8189;

        # TUI off by default: it needs a real terminal, so with it on the
        # default the command fails anywhere without one — a CI step, a
        # script, an editor task, an agent shell — with
        # "TUI startup error: terminal entry not found: term not set".
        # Pass `-t` to get the dashboard back:  services -t
        cli.environment.PC_DISABLE_TUI = true;

        services.postgres."pg" = {
          enable = true;

          # Matches docker-compose.yml's postgres:16-alpine, and
          # postgresql_16 is already in the devShell so pg_dump stays
          # compatible with the server (it refuses a newer one).
          package = pkgs.postgresql_16;

          listen_addresses = "127.0.0.1";
          port = 5432;
          dataDir = "./.data/pg";

          # services-flake defaults the superuser to $USER, but every URL in
          # .env.example is postgresql://postgres:postgres@127.0.0.1/... so
          # without this each connection fails with
          #   FATAL: role "postgres" does not exist
          # The password is ignored — local connections are trust-authed,
          # fine for a dev database bound to 127.0.0.1 only.
          superuser = "postgres";

          # Carried over from docker-compose.yml's
          #   command: -c max_locks_per_transaction=1024
          # The schema has a lot of partitions and the default (64) is not
          # enough to migrate or truncate them in one transaction.
          settings.max_locks_per_transaction = 1024;

          # Mirrors db/setup/init-docker-db.sql.
          initialDatabases = [
            { name = "mosaic_dev"; }
            { name = "mosaic_test"; }
          ];
        };

        services.redis."redis" = {
          enable = true;
          bind = "127.0.0.1";
          port = 6379;
          dataDir = "./.data/redis";

          # Carried over from docker-compose.yml's
          #   command: redis-server --databases 32
          # This repo splits cache, locks and Sidekiq across separate Redis
          # database numbers (CACHE_REDIS_HOST, LOCK_REDIS_HOST,
          # SIDEKIQ_REDIS_HOST), and the default limit of 16 is not enough.
          extraConfig = "databases 32";
        };

        # ── The app itself ─────────────────────────────────────
        # restart = "no" is deliberate: both need gems, and on a fresh
        # checkout there are none — restarting on failure would bury the one
        # line that says so under an endless crash loop.
        settings.processes = {
          app = {
            # Interpolated, not passed as a derivation: `command` runs a
            # bare derivation through lib.getExe, which appends /bin/<name>
            # to what is already a plain script file and dies with
            # "Not a directory" (exit 126).
            command = "${appProcess "rails-api-app" "bundle exec rails server -b 127.0.0.1 -p 3000"}";
            depends_on = {
              pg.condition = "process_healthy";
              redis.condition = "process_healthy";
            };
            availability.restart = "no";
          };

          sidekiq = {
            command = "${appProcess "rails-api-sidekiq" "bundle exec sidekiq"}";
            depends_on = {
              pg.condition = "process_healthy";
              redis.condition = "process_healthy";
            };
            availability.restart = "no";
          };
        };
      };

      # ── direnv (`use flake …#mosaic-rails-api`) ─────────────────────────
      devShells."mosaic-rails-api" = pkgs.mkShell {
        name = "mosaic-rails-api";

        packages =
          with pkgs;
          [
            # ── Language runtime ────────────────────────────────────────────
            # ruby_4_0 is exactly 4.0.6 — what .ruby-version pins, what the
            # Gemfile enforces via `ruby File.read(".ruby-version").strip`, and
            # what the Dockerfile builds on (ruby:4.0.6-slim).
            #
            # Bundler is handled in the shellHook, not here. ruby_4_0 ships
            # bundler 4.0.16 as a DEFAULT gem, but Gemfile.lock says
            # `BUNDLED WITH 2.7.2` and bin/bundle enforces it, so a bare
            # `bundle` dies with:
            #   Activating bundler (~> 2.7) failed:
            #   Could not find 'bundler' (~> 2.7) - did find: [bundler-4.0.16]
            #
            # pkgs.bundler can't fix this: it is built against ruby 3.4.9, so it
            # would run bundle under the wrong interpreter and trip the Gemfile's
            # own `ruby 4.0.6` check. Overriding it onto ruby_4_0 doesn't work
            # either — a default gem shadows anything added to GEM_PATH, and
            # BUNDLER_VERSION does not override it.
            #
            # The Dockerfile hits the identical problem on ruby:4.0.6-slim and
            # solves it with `gem install bundler -v 2.7.2` (Dockerfile line 19).
            # The shellHook mirrors that exactly.
            ruby_4_0

            # ── Databases / services (clients, not servers) ─────────────────
            # Servers come from `services` above: postgres 16, redis.
            # Client major matched to the server so pg_dump/pg_restore — used by
            # `make proddump_by_team_id` and `make partydump_by_team_id` — stay
            # compatible; pg_dump refuses to read a server newer than itself.
            postgresql_16
            redis

            # ── Ruby tooling ───────────────────────────────────────────────
            # Also on PATH for editors: neovim resolves LSPs from PATH.
            # Built against ruby 4.0 so they load under the same interpreter.
            ruby-lsp
            # standardrb is deliberately NOT taken from nixpkgs here.
            # rubyPackages_4_0.standard is broken under ruby 4.0.6 — running it
            # dies in rubygems' own resolver with
            #   Gem::Resolver::Conflict#conflicting_dependencies:
            #   undefined method 'request' for nil (NoMethodError)
            # and, because it sits on GEM_PATH, it takes rubocop down with it.
            # (rubyPackages_3_4.standard is fine, which is why mosaic-api-server
            # can use it — this is specific to the ruby-4.0 gem set.)
            #
            # It is also the wrong version: this repo pins standard 1.54.0 and
            # rubocop 1.84.2 in Gemfile.lock, while nixpkgs has 1.51.1 / 1.80.2 —
            # linting against a different version than CI is its own bug.
            # `make lint` runs ./bin/standardrb and check_complexity runs
            # `bundle exec rubocop`, so both come from the bundle. $PWD/bin is on
            # PATH below, so the editor picks up the same binstubs.

            # Safe on its own (verified) and handy for one-off checks outside a
            # bundle; the Makefile targets still go through `bundle exec`.
            rubocop

            # brakeman is deliberately absent. `make security_scan` runs
            # `bundle exec brakeman`, so it comes from the Gemfile (7.1.1) and a
            # nix copy would never be used — and nixpkgs marks brakeman
            # unfreeRedistributable, which would force allowUnfree just to
            # evaluate this flake.

            # ── Build deps for native gem extensions ───────────────────────
            # pg and nokogiri ship precompiled arm64-darwin builds in the lock,
            # so a normal `bundle install` compiles very little — these cover
            # the gems that do.
            pkg-config
            libyaml
            openssl
            zlib

            # sidekiq-ent -> einhorn -> fiddle builds against libffi, and
            # fiddle ships no precompiled darwin binary. Without this the
            # very first `bundle install` on a clean checkout dies at
            #   fatal error: 'ffi/ffi.h' file not found
            # which reads like a broken Gemfile rather than a missing
            # system header.
            libffi

            # ── General ────────────────────────────────────────────────────
            gnumake # lint / test / openapi / security_scan all go through it
            git
            curl
            jq
          ]
          ++ [
            # `services` — the process-compose stack above, run from the repo root.
            (mosaicLib.servicesWrapper "mosaic-rails-api-services")
          ];

        shellHook = ''
          # Keep gems inside the repo rather than a global GEM_HOME.
          export BUNDLE_PATH="$PWD/vendor/bundle"

          # Project-local gem prefix for the one gem we must install
          # ourselves (bundler 2.7.2 — see the note above). Keeping it in the
          # repo means no global gem state and nothing to clean up elsewhere.
          export GEM_HOME="$PWD/.gem"
          # Pin the gem SEARCH path too, not just the install path. GEM_HOME
          # alone leaves nixpkgs' own ruby gem dirs on GEM_PATH, and those
          # are built against ruby 3.4 while this shell is ruby 4.0.6 — so
          # loading one of their native extensions dies with
          #   LoadError: linked to incompatible .../libruby-3.4.9.dylib
          #     - .../ruby3.4-json-2.16.0/.../json/ext/parser.bundle
          # which takes down anything that boots Rails — `rails
          # db:test:prepare` and `bin/rspec` included. pkgs.rubocop and
          # pkgs.ruby-lsp above are the entry points: both are ruby-3.4
          # builds and drag their closures onto GEM_PATH.
          #
          # This also keeps a stale ~/.local/share/gem out of the picture,
          # which is its own source of shadowed default gems.
          #
          # Safe to isolate: the bundler installed into .gem stays visible
          # (GEM_HOME is on the path), and both rubocop and ruby-lsp are
          # PATH binaries carrying their own lib dirs.
          export GEM_PATH="$GEM_HOME"
          # ...and drop RUBYLIB entirely. GEM_PATH is not enough on its own:
          # pkgs.ruby-lsp and pkgs.rubocop are ruby-3.4 builds and nix puts
          # their lib dirs straight into RUBYLIB, which lands on $LOAD_PATH
          # ahead of everything and bypasses rubygems completely — so
          # `require "json"` resolves to ruby3.4-json inside this ruby-4.0.6
          # shell and dies with
          #   LoadError: linked to incompatible .../libruby-3.4.9.dylib
          # Safe to clear: both are PATH binaries whose nix wrappers set
          # their own RUBYLIB at invocation, so editors still resolve them.
          unset RUBYLIB

          # The repo ships binstubs (bin/rails, bin/rspec, bin/standardrb,
          # bin/spring…). GEM_HOME/bin first so the bundler we install wins.
          export PATH="$GEM_HOME/bin:$PWD/bin:$PATH"

          # Mirrors Dockerfile line 19. Runs once; cached in .gem/ after that.
          if ! gem list -i -v 2.7.2 bundler >/dev/null 2>&1; then
            echo "  installing bundler 2.7.2 (matches Gemfile.lock and the Dockerfile)…"
            gem install bundler -v 2.7.2 --no-document >/dev/null 2>&1 \
              || echo "  ! could not install bundler 2.7.2 — check network"
          fi

          echo ""
          echo "  mosaic-rails-api  ·  ruby $(ruby -e 'print RUBY_VERSION')  ·  $(psql --version | cut -d' ' -f3 | xargs echo psql)"
          echo ""

          # Same private sidekiq-pro source as mosaic-api-server (Gemfile line
          # 44). Without the credential `bundle install` fails partway with a
          # 401 that does not name the cause. The .envrc pulls it from 1Password.
          if [ -z "''${BUNDLE_ENTERPRISE__CONTRIBSYS__COM:-}" ]; then
            echo "  ! BUNDLE_ENTERPRISE__CONTRIBSYS__COM is not set."
            echo "    sidekiq-pro will fail to install (401 from enterprise.contribsys.com)."
            echo ""
          fi

          if [ ! -f .env ]; then
            echo "  ! No .env — copy the template:"
            echo "      cp .env.example .env"
            echo ""
          fi

          cat <<'EOT'
            bundle install                         install gems into vendor/bundle
            bin/rails db:create db:migrate          set up the database
            services                               EVERYTHING: postgres :5432, redis :6379,
                                                   rails :3000, sidekiq — no Docker
            services -t                            same, with the dashboard TUI
            make test                               rspec
            make lint                               standardrb --fix
            make check_complexity                   rubocop metrics
            make check_mosaic_cops                  custom mosaic cops
            make security_scan                      brakeman
            make openapi                            generate + lint the OpenAPI spec

          Service state lives in ./.data — `rm -rf .data` is a clean reset.
          app and sidekiq need gems, so run `bundle install` before the first
          `services` or those two will exit straight away.
          If a service will not start and the log names another PID holding
          .data, a previous run was killed hard and its children outlived it.
          `rm -rf .data` will NOT help — those are live processes:
            lsof -nP -iTCP:5432 -iTCP:6379 -iTCP:3000 -sTCP:LISTEN

          ruby-lsp resolves gems through bundler, so it only works after
          `bundle install`, and it needs the BUNDLE_PATH set here. Launch nvim
          from inside this shell (direnv does that on cd), not a bare terminal.
          EOT
          echo ""
        '';
      };
    };
}
