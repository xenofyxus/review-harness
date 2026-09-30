# Sources

One file per system the evidence workflow can read. Each file says how to detect access, what to query, what to write down and what to watch for. They are recipes, not scripts: the workflow reads the file for each source in `config.yml` `evidence.sources` and runs the pieces that fit the harness it is in.

| Source | File | Preferred | Fallback | Best for |
|---|---|---|---|---|
| GitHub | `github.md` | `gh` CLI, authenticated | GitHub MCP connector | Merged PRs, reviews given for others, PR sizes. The most reliable volume numbers. |
| GitLab | `gitlab.md` | `glab` CLI | REST and GraphQL with `GITLAB_TOKEN` and `GITLAB_HOST` | The same for GitLab shops: merged MRs, approvals given, MR sizes. |
| Linear | `linear.md` | Linear MCP connector | GraphQL with `LINEAR_API_KEY` | Issues closed, projects led, milestones hit. What the code was for. |
| Jira | `jira.md` | Atlassian MCP connector | REST v3 with `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` | Issues resolved and reported, epics carried, support and ops queues. |
| Slack | `slack.md` | Slack MCP connector | Web API with `SLACK_USER_TOKEN` | Moments: announcements, decisions, pushback, thanks, incidents. |
| Notes | `notes.md` | Files in the workspace | none needed | The owner's own memory, and the development feedback given last cycle. |

Order matters. Code and tickets first, because they give you the project names. Slack after, because you search it by those names. Notes whenever, because they are already on disk. `evidence.sources` in `config.yml` sets the order for a workspace, and a source that is not reachable is skipped and listed under `## Not found`.

Every source is read-only. Nothing in this folder creates, edits, comments, reacts or assigns.

## Adding a source

Copy the structure of `github.md` or `linear.md` (Detect, queries with shell blocks, What to write down, Watch for) into `harness/sources/<name>.md`, and keep every call read-only.

Add `<name>` to the `evidence.sources` list in `harness/templates/config.yml`, plus any handle or key it needs under `me.handles` and `evidence`.

Add a row to the detection table in `harness/workflows/evidence.md` so the workflow knows to try it.
