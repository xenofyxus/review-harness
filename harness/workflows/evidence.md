# Workflow: evidence

Pull what the work systems say the person did over the review window, theme it, link it, and turn it into prompts for the interview. Run this before the interview for any review where the owner would otherwise be working from memory.

**Argument:** `<slug>`. For `self`, the subject is the owner. For anyone else, the subject is that person and the owner's handles are only used to find shared work.

This workflow reads. It never writes to any external system.

## 1. Scope

Resolve the workspace as `AGENTS.md` says. Read `<workspace>/config.yml`. Take the window (`evidence.window_months`, default six), the sources list, and the subject's handles: from the **Handles** line of `<workspace>/people/<slug>.md`, or, for `self`, from `me.handles` in the config. If a handle you need is blank, ask for it once and write it back to that line.

State the window as dates before you start, so the owner can correct it: "Searching 15 March 2026 to today."

## 2. Detect what you can reach

For each source in order, check availability and say what you will use. Detection rules are in `harness/sources/<source>.md`. In short:

| Source | Preferred | Fallback |
|---|---|---|
| GitHub | `gh` CLI, authenticated | GitHub MCP connector |
| GitLab | `glab` CLI | REST with a token |
| Linear | Linear MCP connector | GraphQL with `LINEAR_API_KEY` |
| Jira | Jira MCP connector | REST with a token |
| Slack | Slack MCP connector | Web API with a user token |
| Notes | `<workspace>/cycles/<cycle>/<slug>/notes.md` and `<workspace>/people/<slug>.md` | none needed |

Skip unavailable sources without fuss. Record them under `## Not found` at the end so the owner knows the gaps.

## 3. Search, one source at a time

Follow the recipe in `harness/sources/<source>.md`. The shape is always the same:

1. **Volume.** Counts that anchor the period: merged PRs by repo, PRs reviewed for others, issues closed, incidents handled.
2. **Substance.** Titles, dates and links of the things themselves. For PRs, the title is usually enough. For issues, title plus project. For Slack, the messages that have reactions, that started threads, that announced something, that pushed back on something, that got thanked.
3. **Moments.** Anything that looks like a story: an incident handled after hours, a public decision memo, a talk announced, a mistake owned in public, a launch announcement. These are the best interview prompts.

For Slack in particular: search by the subject's user ID with modifiers like `has:reaction`, `is:thread`, and by the names of projects you already found in GitHub and Linear. Sort by relevance, not only by date; recency alone surfaces noise.

Keep a working file as you go so nothing is lost if the session ends: write raw findings to `<workspace>/cycles/<cycle>/<slug>/evidence-raw.md`. Keep it when you are done; setup ignores it in git. Delete it only if the owner asks.

## 4. Theme

Group everything by what it was for, not by where it came from. A launch is one theme even if it spans forty PRs, six tickets and a Slack announcement. Typical themes: a project shipped, reliability and incidents, tooling and process, knowledge sharing, cross-team work, compliance, cleanup.

For each theme, three to eight lines. What happened, when, what the subject did. Every line carries a link. Do not interpret. "Led the carrier migration, 18 issues, all done, cut over 24 June" is evidence. "Showed strong ownership" is not.

## 5. Write `evidence.md`

Fill `harness/templates/evidence.md` and save it to `<workspace>/cycles/<cycle>/<slug>/evidence.md`. The last two sections matter most:

- **Moments worth asking about.** Dated, linked, one line each.
- **Prompts for the interview.** For each question in the review's format, one or two candidates the interviewer can offer. Phrase them as questions. "Q1: the payments launch or the insurance integration, which one and why?"

Set `evidence: yes` in `<workspace>/cycles/<cycle>/<slug>/progress.md` if it exists.

## 6. Report

Tell the owner, in a short message: the window, the sources used and skipped, the volume table, the themes as one line each, and the path of the file. Ask if anything important is missing. Then stop. The interview is a separate step.

## Reviewing other people

For a self review, search freely. For a review of someone else, stay with what you could see anyway: their PRs, their tickets, messages in channels you are in, your own conversations with them. Do not go looking for private channels you are not part of, and do not include anything from a third person's private message about the subject. When in doubt, leave it out and tell the owner why.
