# mosaic-web — React / webpack frontend development environment
#
# No local services: the frontend talks to whichever backend .env.<target>
# points at, so there is no process-compose stack and no `services` here.
_: {
  perSystem =
    { pkgs, ... }:
    {
      # ── direnv (`use flake …#mosaic-web`) ───────────────────────────────
      devShells."mosaic-web" = pkgs.mkShell {
        name = "mosaic-web";

        packages = with pkgs; [
          # ── Runtime ─────────────────────────────────────────────────────
          # package.json engines: "^22.18.0 || >=24.11.0"; the Dockerfile
          # builds on node:22.22.3. nodejs_22 satisfies the 22.x branch, which
          # is the one CI and the image actually use — so stay on it rather
          # than jumping to 24 and diverging from the build.
          nodejs_22

          # yarn CLASSIC (1.22.x). yarn.lock is "yarn lockfile v1", so this
          # must NOT be pkgs.yarn-berry — Berry would rewrite the lockfile
          # into its own format on first install.
          yarn

          # ── Build helpers ───────────────────────────────────────────────
          # node-gyp needs a Python for dependencies with native bindings.
          python3
          # postinstall runs `patch-package; yarn generate-sri`, and
          # generate-sri is scripts/integrity_checks.sh — a bash script using
          # arrays, so /bin/sh is not enough.
          bash

          # ── Language servers ────────────────────────────────────────────
          # On PATH here as well as in the editor config so the shell alone
          # gives working LSPs. vtsls is omitted deliberately: it picks up the
          # workspace TypeScript from node_modules, which is what you want for
          # the pinned version.
          vscode-langservers-extracted # eslint / json / html / css
          typescript-language-server

          # ── General ─────────────────────────────────────────────────────
          git
          curl
          jq
        ];

        shellHook = ''
          # Local binaries first so eslint, vitest, storybook and env-cmd
          # resolve to this repo's pinned versions.
          export PATH="$PWD/node_modules/.bin:$PATH"

          echo ""
          echo "  mosaic-web  ·  node $(node --version)  ·  yarn $(yarn --version)"
          echo ""

          # The four @mosaicapp/* dependencies are PRIVATE packages on
          # registry.npmjs.org, and npm answers unauthenticated requests for
          # a private package with a 404 — so a missing token surfaces as
          #   error .../@mosaicapp/command-palette/-/...tgz: 404 Not Found
          # partway through `yarn install`, which reads like a deleted
          # package rather than a credential problem. Warn up front instead.
          if [ -z "''${NPM_TOKEN:-}" ]; then
            echo "  ! NPM_TOKEN is not set."
            echo "    The four @mosaicapp/* deps are private; yarn install will"
            echo "    fail with a misleading 404. See the envrc for the wiring."
            echo ""
          fi

          # Every script goes through `env-cmd .env.<target>`, so a missing
          # file breaks that target rather than the whole shell.
          missing=""
          for f in .env.local .env.test; do
            [ -f "$f" ] || missing="$missing $f"
          done
          if [ -n "$missing" ]; then
            echo "  ! Missing env file(s):$missing"
            echo "    Scripts invoke env-cmd .env.<target>; start with .env.template."
            echo ""
          fi

          cat <<'EOT'
            yarn install                           deps + patch-package + SRI generation

            yarn start-local                       dev server against .env.local
            yarn start-party                       dev server against .env.party
            yarn build-local                       production build, .env.local

            yarn test                              vitest (uses .env.test)
            yarn test-coverage                     vitest with coverage
            yarn lint                              eslint
            yarn tsc                               typecheck
            yarn storybook                         storybook on :6006

          Builds pass --openssl-legacy-provider already (webpack 4-era hashing
          vs OpenSSL 3); no NODE_OPTIONS needed on your side.
          EOT
          echo ""
        '';
      };
    };
}
