# Agent directory symlinks — connects .agents/ to .claude/
# Set enable = true when ready to activate
{ config, lib, ... }:
let
  enable = false;
  projectDir = "${config.home.homeDirectory}/nixac";
in
lib.mkIf enable {
  # Agent directory symlinks
  #
  # Structure:
  #   .agents/skills/<name>/SKILL.md   — auto-discovered skills (Claude)
  #   .agents/commands/<name>.md       — slash commands (/name)
  #   .agents/agents/<name>.md         — multi-role agents (@name)
  #
  # .claude/ → dir symlinks to .agents/{skills,commands,agents}
  home.activation.agentSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    project="${projectDir}"
    agents="$project/.agents"

    # Ensure target directories exist before symlinking
    $DRY_RUN_CMD mkdir -p "$agents/skills" "$agents/commands" "$agents/agents"

    # .claude/ ← .agents/{skills, commands, agents}  (directory symlinks)
    $DRY_RUN_CMD mkdir -p "$project/.claude"
    $DRY_RUN_CMD ln -sfn "$agents/skills"   "$project/.claude/skills"
    $DRY_RUN_CMD ln -sfn "$agents/commands" "$project/.claude/commands"
    $DRY_RUN_CMD ln -sfn "$agents/agents"   "$project/.claude/agents"

    # Claude auto-memory → repo .agents/memory/
    # Auto-dream and auto-memory write to ~/.claude/projects/<encoded-path>/memory/
    # The encoded path replaces '/' with '-' in the absolute project path.
    # Symlink it to the repo so memory is version-controlled and shared across agents.
    encoded=$(echo "$project" | sed 's|/|-|g')
    claude_memory="$HOME/.claude/projects/$encoded/memory"
    repo_memory="$agents/memory"
    $DRY_RUN_CMD mkdir -p "$repo_memory"
    if [ -d "$claude_memory" ] && [ ! -L "$claude_memory" ]; then
      # First activation: copy any existing memories, then replace with symlink
      $DRY_RUN_CMD cp -n "$claude_memory"/*.md "$repo_memory/" 2>/dev/null || true
      $DRY_RUN_CMD /bin/rm -rf "$claude_memory"
    fi
    $DRY_RUN_CMD mkdir -p "$(dirname "$claude_memory")"
    $DRY_RUN_CMD ln -sfn "$repo_memory" "$claude_memory"
  '';
}
