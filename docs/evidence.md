# Evidence sources

The evidence workflow ([evidence.md](../harness/workflows/evidence.md)) reads what the work systems say the subject did over the review window and turns it into linked themes and interview prompts. It only reads. This page is the setup per source; the query recipes live in [harness/sources/](../harness/sources/).

## Connectors and shell fallbacks

Each source has a preferred path and a fallback. The preferred path is usually an MCP connector, a tool the AI harness can call directly. The fallback is a CLI or an API token in an environment variable, used from the shell.

MCP support depends on the harness. Claude Code and Cursor support MCP servers today, and claude.ai has connectors for Linear and Slack. Codex, Gemini CLI, OpenCode and others vary, and it changes often, so check yours; [harnesses.md](./harnesses.md) lists how each one loads the commands. The shell fallbacks work anywhere the agent can run commands, which is every harness this repository is written for.

The workflow detects each source in the order of `evidence.sources` in `config.yml`, says what it will use, and skips what it cannot reach. Skipped sources end up under `## Not found` in the evidence file.

## Setup per source

Handles go in `workspace/config.yml` under `me.handles` for a self review, or in `workspace/people/<slug>.md` for anyone else. The workflow asks once for a missing handle and saves it back.

### GitHub

| Step | How |
|---|---|
| Authenticate | `gh auth login`, then `gh auth status` to confirm |
| Orgs to search | `evidence.github_orgs` in `config.yml`; left empty, the workflow lists your orgs |
| Handle | GitHub login in `handles.github` |
| Fallback | GitHub MCP connector if `gh` is missing |

Recipe: [harness/sources/github.md](../harness/sources/github.md).

### GitLab

| Step | How |
|---|---|
| Authenticate | `glab auth login`, or set `GITLAB_TOKEN` with the `read_api` scope |
| Self-hosted | `GITLAB_HOST` with the instance URL |
| Handle | GitLab username in `handles.gitlab` |

Recipe: `harness/sources/gitlab.md`.

### Linear

| Step | How |
|---|---|
| Connector | Linear MCP connector in Claude Code or claude.ai |
| Fallback | Personal API key from Linear settings, exported as `LINEAR_API_KEY` |
| Handle | Display name or email in `handles.linear` |

Recipe: [harness/sources/linear.md](../harness/sources/linear.md).

### Jira

| Step | How |
|---|---|
| Connector | Jira MCP connector, where the harness has one |
| Fallback | `JIRA_BASE_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` in the environment |
| Handle | Account ID or email in `handles.jira` |

Recipe: `harness/sources/jira.md`.

### Slack

| Step | How |
|---|---|
| Connector | Slack MCP connector, where the harness has one |
| Fallback | A user token with the `search:read` scope, exported as `SLACK_USER_TOKEN` |
| Handle | Member ID, starts with `U`, in `handles.slack`. Open a profile, the three dots menu, Copy member ID. |

A user token searches as you, including your direct messages. See [privacy.md](./privacy.md). Recipe: [harness/sources/slack.md](../harness/sources/slack.md).

### Notes

Nothing to set up. The workflow reads `cycles/<cycle>/<slug>/notes.md` and the "Things I want to remember" section of `people/<slug>.md`. Recipe: [harness/sources/notes.md](../harness/sources/notes.md).

## What the evidence file looks like

`evidence.md` follows [harness/templates/evidence.md](../harness/templates/evidence.md): a volume table, themes with a link on every line, dated moments, a prompt or two per question, and a list of what was not found. Shortened, with an invented subject:

```markdown
# Evidence for Priya Nair, 1 April to 30 September 2026

## Volume
| | |
|---|---|
| Merged PRs | 41 (28 billing-api, 13 web) |
| PRs reviewed for others | 57 |

## Themes

### Bramble migration
2026-05-12 billing-api#412 Move invoice storage to Bramble https://...
2026-06-03 NW-231 Cut over EU tenants, done https://...

## Moments worth asking about
2026-07-18 Ran the rollback in #incidents after the tenant cutover https://...

## Prompts for the interview
Q1: the Bramble migration (link) or the review load, 57 PRs for others? Which one and why?
```

Everything in it is what the systems show. What it means is for the interview.

## Correcting it by hand

The file is markdown and the interview reads whatever is in it, so edit freely. Delete a line that was someone else's work. Fix a misattributed Slack message; two people with the same first name is the usual cause, and the recipe says to check the member ID. Add a line with a link for something the search missed. If you remove a theme, remove the prompt that pointed at it too, or ask the harness to rebuild the prompts section.

To redo a single source, say so: "rerun evidence for priya, Slack only, keep the rest". Raw findings sit in `evidence-raw.md` while the workflow runs, so a session that stops halfway can pick up from there. That file is gitignored.

Related: [how-it-works.md](./how-it-works.md), [customizing.md](./customizing.md) for the window and for adding a source.
