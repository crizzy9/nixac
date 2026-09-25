# mosaic-ai-server — NestJS / Node 22 / Prisma development environment + local services
{ inputs, ... }:
{
  perSystem =
    { pkgs, mosaicLib, ... }:
    {
      # ── `services` ────────────────────────────────────────────────────────
      # Postgres (+pgvector), Redis and Kafka as ORDINARY LOCAL PROCESSES —
      # no Docker, no VM. Replaces three separate
      #   docker compose -f dependencies/docker-compose.<x>.yml up -d
      # invocations with one command, and on macOS skips the Linux VM those
      # need entirely.
      #
      # Ports match dependencies/*.yml so an existing .env keeps working.
      # State lives in ./.data (gitignored) — `rm -rf .data` is a full reset.
      #
      # NOT covered here, still Docker-only:
      #   • Langfuse (docker-compose.langfuse.yml) — optional LLM tracing,
      #     and it drags in ClickHouse + MinIO.
      #   • Pinot (docker-compose.pinot.yml).
      #   • The Redis SENTINEL topology in docker-compose.redis.yml. What
      #     runs here is a single standalone Redis, which is what the app
      #     needs for ordinary local work; use the compose file if you are
      #     specifically testing failover behaviour.
      process-compose."mosaic-ai-server-services" = {
        imports = [ inputs.services-flake.processComposeModules.default ];

        services.postgres."pg" = {
          enable = true;

          # dependencies/docker-compose.postgres.yml runs pgvector/pgvector:pg17
          package = pkgs.postgresql_17;
          extensions = exts: [ exts.pgvector ];

          listen_addresses = "127.0.0.1";
          # That compose file publishes 15432:5432, so the host-side port
          # any existing .env already points at is 15432.
          port = 15432;
          dataDir = "./.data/pg";

          # services-flake defaults the superuser to $USER; the container
          # image defaults to `postgres`, which is what connection strings
          # written against it will assume.
          superuser = "postgres";

          initialDatabases = [
            { name = "ai_server_development"; }
            { name = "ai_server_development_test"; }
          ];

          # pgvector ships as an extension but still has to be enabled per
          # database before Prisma can create a `vector` column.
          initialScript.after = ''
            \connect ai_server_development
            CREATE EXTENSION IF NOT EXISTS vector;
            \connect ai_server_development_test
            CREATE EXTENSION IF NOT EXISTS vector;
          '';
        };

        services.redis."redis" = {
          enable = true;
          bind = "127.0.0.1";
          port = 6379;
          dataDir = "./.data/redis";
        };

        # KRaft mode — no ZooKeeper process to run alongside.
        #
        # All of the settings below are REQUIRED: with only `port` set,
        # Kafka 4.x refuses to boot with
        #   ConfigException: Missing required configuration "process.roles"
        # because KRaft has no ZooKeeper to infer its role from.
        #
        # Ports match dependencies/docker-compose.kafka.yml, which publishes
        # both 29092 (broker) and 29093 (controller).
        services.apache-kafka."kafka" = {
          enable = true;
          port = 29092;
          dataDir = "./.data/kafka";

          # KRaft stores the cluster identity in the log dir; formatLogDirs
          # runs `kafka-storage format` on first boot so it exists.
          clusterId = "MosaicAiLocalDevCluster";
          formatLogDirs = true;

          settings = {
            "node.id" = 1;
            "process.roles" = "broker,controller";
            "listeners" = [
              "PLAINTEXT://127.0.0.1:29092"
              "CONTROLLER://127.0.0.1:29093"
            ];
            "advertised.listeners" = [ "PLAINTEXT://127.0.0.1:29092" ];
            "controller.quorum.voters" = "1@127.0.0.1:29093";
            "controller.listener.names" = "CONTROLLER";
            "inter.broker.listener.name" = "PLAINTEXT";
            # Single-node dev broker: anything above 1 leaves every
            # internal topic under-replicated and stuck.
            "offsets.topic.replication.factor" = 1;
            "transaction.state.log.replication.factor" = 1;
            "transaction.state.log.min.isr" = 1;
          };
        };
      };

      # ── direnv (`use flake …#mosaic-ai-server`) ─────────────────────────
      devShells."mosaic-ai-server" = pkgs.mkShell {
        name = "mosaic-ai-server";

        packages =
          with pkgs;
          [
            # ── Runtime ───────────────────────────────────────────────────
            # .nvmrc says 22 and package.json engines require >=22.22.1;
            # nixpkgs nodejs_22 satisfies both. npm ships with it.
            nodejs_22

            # node-gyp needs a Python for dependencies with native bindings.
            python3

            # ── Service clients (servers come from `services`) ────────────
            postgresql_17 # psql
            redis # redis-cli

            # ── Language servers ──────────────────────────────────────────
            # On PATH here as well as in the editor config so the shell alone
            # gives working LSPs. vtsls deliberately omitted: it picks up the
            # workspace TypeScript from node_modules, which is what you want.
            vscode-langservers-extracted # eslint / json / html / css
            prisma-language-server
            typescript-language-server

            # ── General ───────────────────────────────────────────────────
            gnumake
            git
            curl
            jq
          ]
          ++ [
            # `services` — the process-compose stack above, run from the repo root.
            (mosaicLib.servicesWrapper "mosaic-ai-server-services")
          ];

        shellHook = ''
          # Local npm binaries first, so `nest`, `prisma`, `jest` resolve to
          # the versions this repo pins rather than anything global.
          export PATH="$PWD/node_modules/.bin:$PATH"

          # NOTE ON PRISMA — deliberately NOT setting
          # PRISMA_QUERY_ENGINE_LIBRARY and friends to nixpkgs
          # prisma-engines.
          #
          # nixpkgs ships prisma-engines 7.x while package.json pins
          # @prisma/client ^6.19; the engine protocol is version-locked, so
          # pointing 6.x at 7.x engines fails at runtime. On darwin there is
          # no reason to: the engines npm downloads are ordinary signed
          # macOS binaries that run fine outside the Nix store. Let npm own
          # them. (On NixOS you WOULD need the overrides, with matching
          # versions.)

          echo ""
          echo "  mosaic-ai-server  ·  node $(node --version)  ·  npm $(npm --version)"
          echo ""

          # Only meaningful outside direnv. Under direnv the .envrc fetches
          # these from 1Password BEFORE `use flake` (that ordering is
          # load-bearing — see the comment in the envrc), and op_notes_export
          # reports its own failures.
          if [ -z "''${DIRENV_IN_ENVRC:-}" ] && [ -z "''${NPM_TASKFORCESH_TOKEN:-}" ]; then
            echo "  ! NPM_TASKFORCESH_TOKEN is not set."
            echo "    npm install will 401 on @taskforcesh/* (see .npmrc)."
            echo "    Inside direnv this is fetched from 1Password automatically."
            echo ""
          fi

          # The Makefile does a bare `include .env`, so it errors out
          # entirely when the file is missing — not just for env-dependent
          # targets.
          if [ ! -f .env ]; then
            echo "  ! No .env — required by the Makefile and the apps."
            echo "    Copy the sample from 1Password (README step 2), then: touch .env"
            echo ""
          fi

          cat <<'EOT'
            services                 postgres+pgvector :15432, redis :6379, kafka :29092
            services -t              same, with the dashboard TUI
            npm install              deps + prisma client generation (postinstall)
            npm run migrate:ai       apply AI database migrations

            npm run start:dev                                     watch mode
            npm run build:ai-api && npm run start:prod:ai-api      general APIs
            npm run build:ai-consumer-service && npm run start:prod:ai-consumer-service
            npm run build:ai-conversation-controller && npm run start:prod:ai-conversation-controller
            npm run build:ai-conversation-service && npm run start:prod:ai-conversation-service

            npm test                 jest
            npm run lint             eslint --fix
            npm run format           prettier

          Service state lives in ./.data — `rm -rf .data` is a clean reset.
          Langfuse, Pinot and the Redis sentinel topology are still
          docker-only; see dependencies/*.yml.
          EOT
          echo ""
        '';
      };
    };
}
