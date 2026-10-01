# Privacy

Reviews contain candid judgments about real colleagues, and the evidence workflow reads your work systems to prepare for them. This page says what the workflows touch, where it goes, and what stays with you.

## What the workflows touch

| Data | Where it lives | Who wrote it |
|---|---|---|
| Your name, role, handles, the people you review | `workspace/config.yml`, `workspace/people/` | You, through setup |
| Your past writing | `workspace/voice/samples/`, `workspace/voice/profile.md` | You; the profile quotes you |
| PR titles, issue titles, message gists, with links | `workspace/cycles/<cycle>/<slug>/evidence.md` | The evidence workflow |
| Your interview answers, in compact form | `progress.md` | The review workflow |
| The review itself | `review.md` | The review workflow, from your words |

All of it is plain text on your disk. No workflow uploads anything itself. What your AI harness sends to its model is a separate matter, covered at the end of this page.

## Evidence gathering only reads

The evidence workflow queries GitHub, GitLab, Linear, Jira and Slack for what the subject did in the window. It never writes: no comments, no reactions, no messages, no issue updates. The recipes in [harness/sources/](../harness/sources/) are search and read calls only, and [evidence.md](../harness/workflows/evidence.md) says so near the top.

There is one thing to know about Slack. A user token, or a Slack MCP connector acting as you, searches everything you can see, including your own direct messages and the private channels you are in. The recipes filter by the subject's member ID, so results are their messages in places you already are, but the search has that reach. If that is not acceptable, leave `slack` out of `evidence.sources` in `config.yml`.

## Private repo or gitignore

The workspace is committed by default, so a private clone of this repository doubles as your review archive with history. Setup checks the visibility of the repository it finds itself in and warns if it is public.

If you would rather keep the workspace out of git entirely, uncomment the two `workspace/**` lines in [.gitignore](../.gitignore). Either choice is fine. Committing to a public repository is not, and the harness will say so.

## Reviewing other people

For a self review, search freely. It is your work.

For a review of someone else, stay with what you could see anyway: their pull requests, their tickets, messages in channels you are a member of, and your own conversations with them. Do not go looking for private channels you are not part of, and do not include anything a third person said about the subject in a private message, even one sent to you. When in doubt, leave it out. The workflow lists what it skipped under `## Not found` in the evidence file.

## Your AI harness sees everything

Whatever harness you run this with, Claude Code, Cursor, Codex, Gemini CLI, OpenCode or another, reads the files it works on and sends them to a model. That includes your evidence, your interview answers and the finished review. The markdown in this repository cannot change that. Pick a harness and a plan whose data retention and training policy you accept for this kind of content, and check whether your company has a view on it first.

Related: [evidence.md](./evidence.md) for what each source needs, [how-it-works.md](./how-it-works.md) for the flow.
