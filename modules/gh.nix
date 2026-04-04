# GitHub CLI
{ ... }:
{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    gitCredentialHelper.enable = true;
  };
}
