# Evidence sources

The evidence workflow ([evidence.md](../harness/workflows/evidence.md)) reads what the work systems say the subject did over the review window and turns it into linked themes and interview prompts. It only reads. This page is the setup per source; the query recipes live in [harness/sources/](../harness/sources/).

## Connectors and shell fallbacks

Each source has a preferred path and a fallback. For GitHub and GitLab the preferred path is the CLI, `gh` or `glab`, authenticated on your machine. For Linear, Jira and Slack it is an MCP connector, a tool the harness can call directly. For GitHub the fallback is the GitHub MCP connector, where your harness has one. For the others it is a token from the shell: an API key or user token in an environment variable, used with `curl`.

Whether an MCP connector is available depends on your harness and how you configured it. The shell fallbacks work anywhere the harness can run commands, which is every harness this repository is written for. They need a POSIX shell with curl; on Windows use Git Bash or WSL. [harnesses.md](./harnesses.md) lists how each harness loads the commands.

The workflow detects each source in the order of `evidence.sources` in `config.yml`, says what it will use, and skips what it cannot reach. Skipped sources end up under `## Not found` in the evidence file.

## Setup per source

The owner's handles live in `workspace/config.yml` under `me.handles`. Everyone else's are on the **Handles:** line of `workspace/people/<slug>.md`. The workflow asks once for a missing handle and writes it back to that line.

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
| Enable | Add `gitlab` to `evidence.sources` in `config.yml`; groups to search in `evidence.gitlab_groups` |
| Authenticate | `glab auth login`, or set `GITLAB_TOKEN` with the `read_api` scope |
| Self-hosted | `GITLAB_HOST` with the instance URL |
| Handle | GitLab username in `handles.gitlab` |

Recipe: [harness/sources/gitlab.md](../harness/sources/gitlab.md).

### Linear

| Step | How |
|---|---|
| Connector | Linear MCP connector, where the harness has one |
| Fallback | Personal API key from Linear settings, exported as `LINEAR_API_KEY` |
| Handle | Display name or email in `handles.linear` |

Recipe: [harness/sources/linear.md](../harness/sources/linear.md).

### Jira

| Step | How |
|---|---|
| Enable | Add `jira` to `evidence.sources` in `config.yml` |
| Connector | Jira MCP connector, where the harness has one |
| Fallback | `JIRA_BASE_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` in the environment |
| Handle | Account ID or email in `handles.jira` |

Recipe: [harness/sources/jira.md](../harness/sources/jira.md).

### Slack

| Step | How |
|---|---|
| Connector | Slack MCP connector, where the harness has one |
| Fallback | A user token with the `search:read` scope, exported as `SLACK_USER_TOKEN` |
| Handle | Member ID, starts with `U`, in `handles.slack`. Open a profile, the three dots menu, Copy member ID. |

A user token searches as you, including your direct messages. See [privacy.md](./privacy.md). Recipe: [harness/sources/slack.md](../harness/sources/slack.md).

### Notes

Nothing to set up. The workflow reads `workspace/cycles/<cycle>/<slug>/notes.md` and the "Things I want to remember" section of `workspace/people/<slug>.md`. Recipe: [harness/sources/notes.md](../harness/sources/notes.md).

## What the evidence file looks like

`evidence.md` follows [harness/templates/evidence.md](../harness/templates/evidence.md): a volume table, themes with a link on every line, dated moments, a prompt or two per question, and a list of what was not found. Shortened from [the demo workspace](../examples/demo-workspace/cycles/2026-h2/priya/evidence.md), where every name and company is fictional:

```markdown
# Evidence for Priya Nair, 22 March 2026 to 22 September 2026

## Volume
| | |
|---|---|
| Merged PRs | 48 (29 carrier-gateway, 11 webhook-dispatcher, 7 shipping-core, 1 infra) |
| PRs reviewed for others | 61 |

## Themes

### Nordfrakt label API migration (April to July)
Linear project, lead Priya Nair, 18 issues, 18 done, target date 1 July 2026. https://linear.app/...
14 April: carrier-gateway#412 "Add Nordfrakt REST client with token-bucket rate limiting". https://github.com/...
24 June: carrier-gateway#481 "Route Nordfrakt label purchases to REST client by default". https://github.com/...

## Moments worth asking about
12 May, incident run from first message to all-clear in 44 minutes. https://northwind.slack.com/...

## Prompts for the interview
Q1: The Nordfrakt migration (18 issues, cutover 24 June) or the webhook retry work (12 May incident, three PRs, no incidents since)? Which one and why?
```

Everything in it is what the systems show. What it means is for the interview.

## Correcting it by hand

The file is markdown and the interview reads whatever is in it, so edit freely. Delete a line that was someone else's work. Fix a misattributed Slack message; two people with the same first name is the usual cause, and the recipe says to check the member ID. Add a line with a link for something the search missed. If you remove a theme, remove the prompt that pointed at it too, or ask the harness to rebuild the prompts section.

To redo a single source, say so: "rerun evidence for priya, Slack only, keep the rest". Raw findings go to `evidence-raw.md` in the same folder while the workflow runs, so a session that stops halfway can pick up from there. The file is kept when the workflow finishes and it is gitignored. It is deleted only if you ask.

Related: [how-it-works.md](./how-it-works.md), [customizing.md](./customizing.md) for the window and for adding a source.
