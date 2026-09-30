# Workflow: setup

Create or extend a workspace. Run this on first use and at the start of every new cycle.

## 1. Find or create the workspace

Resolve the workspace root as described in `AGENTS.md`. If `config.yml` exists, read it, say what is already configured in a few lines, and ask whether this is a new cycle or a change to people. Otherwise start fresh.

## 2. Ask, briefly

One message with all of these, so the owner can answer in one go. Take defaults where they leave things blank.

- Your name, role and company.
- The language reviews should be written in. Default: the language they are writing to you in.
- A name for this cycle. Suggest one from the current date, like `2026-h2`.
- Who you need to review this cycle: name, relation (manager, peer, report), role. Include yourself if you have a self review.
- Which review formats each one uses. Show the built-in formats from `harness/formats/` in one line and say custom ones can be pasted in later.
- Handles for evidence gathering, all optional: GitHub username, GitHub orgs, Slack member ID, Linear name, Jira account. Say plainly that these are only used to search their own work and that nothing is written anywhere.

## 3. Write the files

1. `config.yml` from `harness/templates/config.yml`. Slugs are lowercase first names, deduplicated with a surname initial if needed.
2. `people/<slug>.md` for each person from `harness/templates/person.md`, with the fields filled and the free-text sections left as prompts.
3. `cycles/<cycle>/README.md` from `harness/templates/cycle-readme.md`.
4. `cycles/<cycle>/<slug>/progress.md` for each review from `harness/templates/progress.md`, with the questions of the chosen format listed and `status: not started`.
5. `voice/samples/README.md` saying: drop past reviews and other writing here, then run the voice workflow. `voice/` and `notes.md` files are for the owner to fill by hand.

Never overwrite an existing `people/` file, `progress.md` or `review.md`. Add, do not replace.

## 4. Privacy check

Reviews contain candid judgments about colleagues. Say this once, plainly:

- If this workspace is inside a git repository, check whether it is private. Try `gh repo view --json visibility -q .visibility` if the `gh` CLI is available. If it reports `PUBLIC`, warn clearly and suggest either making it private or adding `workspace/` to `.gitignore`. Offer to do the latter.
- If there is no repository, say that the files live only on this machine and that a private repo is a reasonable way to keep history.

## 5. Point to the next step

End with three lines: the path of the config, the suggestion to add writing samples and run the voice workflow, and the suggestion to run the evidence workflow before the first interview. Then stop.
