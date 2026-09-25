# mosaic-chat-bots — NestJS / Node 22 chat-platform bots (Teams, Slack) development environment + local Postgres
{ inputs, ... }:
{
  perSystem =
    { pkgs, mosaicLib, ... }:
    {
      # ── `services` ────────────────────────────────────────────────────────
      # The bot's own Postgres as an ORDINARY LOCAL PROCESS — no Docker, no
      # VM. It holds conversation_state, the teams_account_link tables and
      # the Chat SDK's chat_state_* tables (auto-created on first boot), plus
      # the test database the DB-backed specs and the e2e suite need.
      #
      # State lives in ./.data (gitignored) — `rm -rf .data` is a full reset.
      #
      # This is the ONLY service the bot needs of its own. Everything else a
      # full local turn talks to belongs to the sibling repos and runs from
      # their shells: mosaic-ai-server (`services` there → ai-server on :4000
      # with its postgres on :15432) and mosaic-rails-api (rails on :3000
      # with its postgres on :5432).
      process-compose."mosaic-chat-bots-services" = {
        imports = [ inputs.services-flake.processComposeModules.default ];

        # process-compose's HTTP API stays on so `process-compose attach` can
        # reach a detached run — on its own port so a stray detached run in
        # one repo cannot be mistaken for another's: 8189 mosaic-rails-api,
        # 8188 mosaic-api-server, 8187 here.
        cli.options.no-server = false;
        cli.options.port = 8187;

        # TUI off by default: it needs a real terminal, so with it on the
        # command fails anywhere without one (CI, scripts, editor tasks,
        # agent shells) with "TUI startup error: terminal entry not found".
        # Pass `-t` to get the dashboard back:  services -t
        cli.environment.PC_DISABLE_TUI = true;

        services.postgres."pg" = {
          enable = true;

          # .github/workflows/ci.yml runs the tests against postgres:15, so
          # the local server matches what CI exercises.
          package = pkgs.postgresql_15;

          listen_addresses = "127.0.0.1";
          # NOT 15432. src/testing/test-data-source.ts defaults to :15432,
          # which is mosaic-ai-server's postgres (the old devbox
          # `dependencies-postgres-1` container, now that repo's `services`).
          # A full local turn needs ai-server running alongside this bot, so
          # binding the same port here would make the two stacks mutually
          # exclusive exactly when both are wanted. The devShell below
          # exports TEST_DATABASE_URL to match this port.
          port = 15433;
          dataDir = "./.data/pg";

          # services-flake defaults the superuser to $USER; the connection
          # strings in this repo (test-data-source.ts, CI) assume `postgres`.
          # Local auth is trust, so the `password` in those URLs is ignored.
          superuser = "postgres";

          initialDatabases = [
            { name = "chat_bots_development"; }
            { name = "chat_bots_test"; }
          ];
        };
      };

      # ── direnv (`use flake …#mosaic-chat-bots`) ─────────────────────────
      devShells."mosaic-chat-bots" = pkgs.mkShell {
        name = "mosaic-chat-bots";

        packages =
          with pkgs;
          [
            # ── Runtime ───────────────────────────────────────────────────
            # package.json engines say >=20, but the Dockerfile builds on
            # node:22 and ci.yml runs setup-node '22' — so 22 is what the
            # image and CI actually exercise. Same nodejs_22 as
            # mosaic-ai-server and mosaic-web. npm ships with it.
            nodejs_22

            # node-gyp needs a Python for dependencies with native bindings.
            # Nothing in package-lock.json compiles today (pg is pure JS), but
            # this keeps a future native dep from failing `npm install`.
            python3

            # ── Service client (the server comes from `services`) ─────────
            # Same major as the service above so pg_dump never meets a newer
            # server than itself.
            postgresql_15 # psql

            # ── Language servers ──────────────────────────────────────────
            # On PATH here as well as in the editor config so the shell alone
            # gives working LSPs. vtsls is deliberately omitted: it picks up
            # the workspace TypeScript from node_modules, which is what you
            # want for the pinned version.
            vscode-langservers-extracted # eslint / json / html / css
            typescript-language-server

            # ── General ───────────────────────────────────────────────────
            git
            curl
            jq
          ]
          ++ [
            # `services` — the process-compose stack above, run from the repo root.
            (mosaicLib.servicesWrapper "mosaic-chat-bots-services")
          ];

        shellHook = ''
          # Local npm binaries first, so `nest`, `jest`, `tsc` resolve to the
          # versions this repo pins rather than anything global.
          export PATH="$PWD/node_modules/.bin:$PATH"

          # Point the DB-backed specs and the e2e suite at the postgres from
          # `services` (:15433, see above), unless already set.
          # test-data-source.ts's contract: an EXPLICIT URL that is
          # unreachable FAILS the specs — the same as CI — where the bare
          # default would silently green-skip every DB-backed test.
          export TEST_DATABASE_URL="''${TEST_DATABASE_URL:-postgres://postgres:password@localhost:15433/chat_bots_test}"

          echo ""
          echo "  mosaic-chat-bots  ·  node $(node --version)  ·  npm $(npm --version)"
          echo ""

          if [ ! -f .env ]; then
            echo "  ! No .env — the app reads its config from it (see README, Run locally):"
            echo "      cp .env.example .env"
            echo "    then for the local postgres from \`services\` set"
            echo "      DATABASE_URL=postgres://postgres:password@localhost:15433/chat_bots_development"
            echo ""
          fi

          if [ ! -d node_modules ]; then
            echo "  ! No node_modules — run: npm install"
            echo ""
          fi

          cat <<'EOT'
            npm install              deps
            services                 postgres :15433 (chat_bots_development + chat_bots_test)
            services -t              same, with the dashboard TUI

            npm run start:dev        watch mode on :3978 (GET /health)
            npm run build            tsc strict
            npm test                 jest (DB specs use TEST_DATABASE_URL)
            npm run test:e2e         e2e suite (needs the postgres above)

          Service state lives in ./.data — `rm -rf .data` is a clean reset.
          If postgres will not start and the log names another PID holding
          .data, a previous run was killed hard and its child outlived it —
          `rm -rf .data` will NOT help, that is a live process:
            lsof -nP -iTCP:15433 -sTCP:LISTEN

          A full local turn also needs mosaic-ai-server (:4000) and
          mosaic-rails-api (:3000) up from their own shells — see
          AI_SERVER_URL / CONVERSATIONS_API_URL in .env.example.
          EOT
          echo ""
        '';
      };
    };
}
