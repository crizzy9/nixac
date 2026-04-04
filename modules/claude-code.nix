# Claude Code — AI coding assistant with MCP servers
# Set enable = true when ready to activate
{ config, lib, ... }:
let
  enable = false;
in
lib.mkIf enable {
  # Shared MCP servers — written to ~/.config/mcp/mcp.json
  programs.mcp.enable = true;
  programs.mcp.servers = {
    nixos = {
      command = "nix";
      args = [
        "run"
        "github:utensils/mcp-nixos"
        "--"
      ];
    };
    context7 = {
      command = "nix";
      args = [
        "shell"
        "nixpkgs#nodejs_22"
        "-c"
        "npx"
        "-y"
        "@upstash/context7-mcp@latest"
      ];
    };
    github = {
      command = "bash";
      args = [
        "-c"
        "GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) nix run nixpkgs#github-mcp-server -- stdio"
      ];
    };
  };

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      attribution = {
        commit = "";
        pr = "";
      };
      permissions = {
        allow = [
          "Bash(nix-instantiate --eval *)"
          "Bash(nix flake check *)"
          "Bash(yq *)"
          "Bash(git status *)"
          "Bash(git stash *)"
          "Bash(git log *)"
          "Bash(git diff *)"
          "Bash(nix fmt:*)"
          "Bash(nix shell *)"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:raw.githubusercontent.com)"
          "WebFetch(domain:mynixos.com)"
          "WebFetch(domain:claude.com)"
          "WebSearch"
          "mcp__mcp-nixos__nix"
        ];
        deny = [
          "Bash(sudo *)"
          "Bash(rm -rf *)"
          "Bash(git push --force *)"
          "Bash(git add .)"
          "Bash(git add -A)"
        ];
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                command = ''file="$CLAUDE_FILE_PATH"; if echo "$file" | grep -qE '\.nix$'; then echo 'Editing Nix file: ensure dry-build validation after changes'; fi; if echo "$file" | grep -qE '\.ya?ml$'; then echo 'Editing YAML file: validate with yq after changes'; fi'';
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                command = ''file="$CLAUDE_FILE_PATH"; if echo "$file" | grep -qE '\.ya?ml$'; then yq eval '.' "$file" > /dev/null 2>&1 || echo "YAML SYNTAX ERROR in $file"; fi'';
              }
            ];
          }
        ];
      };
    };
  };
}
