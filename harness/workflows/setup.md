# Workflow: setup

Create or extend a workspace. Run this on first use and at the start of every new cycle.

## 1. Find or create the workspace

Resolve the workspace root as `AGENTS.md` says. If `config.yml` exists, read it, say what is already configured in a few lines, and ask whether this is a new cycle or a change to people. Otherwise the workspace root will be `workspace/` under the directory you were started in, unless the owner says they want it to be the directory itself.

## 2. Ask, briefly

One message with all of these, so the owner can answer in one go. Take defaults where they leave things blank.

- Your name, role and company.
- The language reviews should be written in. Default: the language they are writing to you in.
- A name for this cycle. Suggest one from the current date, like `2026-h2`.
- Who you need to review this cycle: name, relation (manager, peer, report), role, and roughly since when you have worked together. Include yourself if you have a self review.
- Which review format each one uses. Show the built-in formats from `harness/formats/` in one line and say custom ones can be pasted in later.
- Handles, all optional, only used to search their own work and never to write anywhere: your GitHub username and orgs, Slack member ID, Linear name, Jira account. For each person you review, their GitHub login and Slack member ID if you know them.

## 3. Write the files

1. `<workspace>/config.yml` from `harness/templates/config.yml`, replacing every demo value with the owner's answers and leaving unknown handles empty. Slugs are lowercase first names, deduplicated with a surname initial if needed; the owner's self review uses the slug `self`.
2. `<workspace>/people/<slug>.md` for each person other than `self`, from `harness/templates/person.md`, with the fields and the **Handles** line filled from what the owner gave and the free-text sections left as prompts.
3. `<workspace>/cycles/<cycle>/README.md` from `harness/templates/cycle-readme.md`.
4. `<workspace>/cycles/<cycle>/<slug>/progress.md` for each review, from `harness/templates/progress.md`, with the questions of the chosen format shortened to their first clause, `status: not started`, and no placeholder text left in.
5. `<workspace>/voice/samples/README.md` saying: drop past reviews and other writing here, then run the voice workflow. `voice/samples/` and `notes.md` are for the owner to fill by hand; the voice workflow writes `voice/profile.md`.

Never overwrite an existing `people/` file, `progress.md` or `review.md`. Add, do not replace.

## 4. Privacy check

Reviews contain candid judgments about colleagues. Say this once, plainly, then check where the files will end up:

- If the workspace is inside a git repository, check whether it is private. Try `gh repo view --json visibility -q .visibility` if the `gh` CLI is available. If it reports `PUBLIC`, warn clearly. If the remote is the upstream Review Harness repository rather than the owner's own, say so and suggest creating a private repository and pointing `origin` at it with `git remote set-url origin <url>` before committing anything. Otherwise suggest either making the repository private or uncommenting the two `workspace/**` lines in `.gitignore`, and offer to do the latter.
- If there is no repository, say that the files live only on this machine and that a private repository is a reasonable way to keep history.

## 5. Point to the next step

End with three lines: the path of the config, the suggestion to add writing samples and run the voice workflow, and the suggestion to run the evidence workflow before the first interview. Then stop.
