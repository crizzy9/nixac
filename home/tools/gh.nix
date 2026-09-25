# GitHub CLI + gh-dash. Ported verbatim from lumino's modules/shell/gh.nix.
#
# Note: the `C`/`O` gh-dash keybindings shell out to Octo (nvim) and `w` to
# worktrunk's `wt` — both present in this config, so they work as-is.
{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      pager = "diffnav";
    };
    gitCredentialHelper.enable = true;
  };

  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
        }
      ];
      issuesSections = [
        {
          title = "My Issues";
          filters = "is:open author:@me";
        }
        {
          title = "Assigned";
          filters = "is:open assignee:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
        }
      ];
      notificationsSections = [
        {
          title = "All";
          filters = "";
        }
        {
          title = "Created";
          filters = "reason:author";
        }
        {
          title = "Participating";
          filters = "reason:participating";
        }
        {
          title = "Mentioned";
          filters = "reason:mention";
        }
        {
          title = "Review Requested";
          filters = "reason:review-requested";
        }
        {
          title = "Assigned";
          filters = "reason:assign";
        }
        {
          title = "Subscribed";
          filters = "reason:subscribed";
        }
        {
          title = "Team Mentioned";
          filters = "reason:team-mention";
        }
      ];
      repo = {
        branchesRefetchIntervalSeconds = 30;
        prsRefetchIntervalSeconds = 60;
      };
      defaults = {
        preview = {
          open = false;
          width = 70;
        };
        prsLimit = 20;
        prApproveComment = "LGTM";
        issuesLimit = 20;
        notificationsLimit = 20;
        view = "prs";
        layout = {
          prs = {
            updatedAt = {
              width = 5;
            };
            createdAt = {
              width = 5;
            };
            repo = {
              width = 20;
            };
            author = {
              width = 15;
            };
            authorIcon = {
              hidden = false;
            };
            assignees = {
              width = 20;
              hidden = true;
            };
            base = {
              width = 15;
              hidden = true;
            };
            lines = {
              width = 15;
            };
          };
          issues = {
            updatedAt = {
              width = 5;
            };
            createdAt = {
              width = 5;
            };
            repo = {
              width = 15;
            };
            creator = {
              width = 10;
            };
            creatorIcon = {
              hidden = false;
            };
            assignees = {
              width = 20;
              hidden = true;
            };
          };
        };
        refetchIntervalMinutes = 30;
      };
      keybindings = {
        universal = [
          {
            key = "g";
            name = "lazygit";
            command = "cd {{.RepoPath}} ; lazygit";
          }
        ];
        prs = [
          {
            key = "C";
            name = "code review";
            command = "cd {{.RepoPath}} ; gh pr checkout {{.PrNumber}} ; nvim -c 'Octo pr edit {{.PrNumber}}'";
          }
          {
            key = "w";
            name = "switch worktree";
            command = "cd {{.RepoPath}} ; wt switch pr:{{.PrNumber}}";
          }
          {
            key = "D";
            name = "diff in diffnav";
            command = "cd {{.RepoPath}} ; gh pr diff {{.PrNumber}} | diffnav";
          }
          {
            key = "O";
            name = "view in nvim (octo)";
            command = "cd {{.RepoPath}} ; nvim -c 'Octo pr edit {{.PrNumber}}'";
          }
        ];
        issues = [
          {
            key = "O";
            name = "view in nvim (octo)";
            command = "cd {{.RepoPath}} ; nvim -c 'Octo issue edit {{.IssueNumber}}'";
          }
        ];
      };
      theme = {
        colors = {
          text = {
            primary = "#F7F1FF";
            secondary = "#5AD4E6";
            inverted = "#F7F1FF";
            faint = "#3E4057";
            warning = "#FC618D";
            success = "#7BD88F";
          };
          background = {
            selected = "#535155";
          };
          border = {
            primary = "#948AE3";
            secondary = "#7BD88F";
            faint = "#3E4057";
          };
        };
        ui = {
          sectionsShowCount = true;
          table = {
            showSeparator = true;
            compact = true;
          };
        };
      };
      pager = {
        diff = "diffnav";
      };
      confirmQuit = false;
      showAuthorIcons = true;
      smartFilteringAtLaunch = true;
    };
  };

  home.packages = with pkgs; [
    diffnav
    delta
    worktrunk
  ];

  # worktrunk (`wt`) — worktrees are the default way of working on Mosaic.
  # Every repo is a bare clone in <repo>/.bare with one directory per branch
  # beside it (~/dev/mosaic/mosaic-rails-api/AI-123), which is the layout
  # hosts/mosaic/envrc expects. This is worktrunk's documented "bare
  # repository" template: repo_path is the .bare dir, so ../<branch> lands
  # inside the container.  `wt switch -c AI-123` creates and cds; `wt switch ^`
  # is the default branch; `wt remove` deletes a merged branch's worktree.
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "{{ repo_path }}/../{{ branch | sanitize }}"
  '';
  # Shell integration makes `wt switch` actually cd, and adds completions.
  programs.zsh.initContent = ''
    eval "$(${pkgs.worktrunk}/bin/wt config shell init zsh)"
  '';
}
