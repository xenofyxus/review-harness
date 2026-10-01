# Workflow: status

Show where every review in the current cycle stands.

1. Resolve the workspace as `AGENTS.md` says and read `<workspace>/config.yml`. Take the current cycle and the `reviews:` list.
2. For each review, read `<workspace>/cycles/<cycle>/<slug>/progress.md` if it exists. Note the status, how many questions are ticked and how many of those read `skipped`, whether `evidence.md` exists, and the `updated:` field.
3. Also list any folders under `<workspace>/cycles/<cycle>/` that are not in `config.yml`, so nothing is forgotten.
4. Present one table: person, format, status, questions (as "3 answered, 1 skipped"), evidence, last updated (`-` when blank).
5. Suggest the next thing to do in one line. Prefer: setup if config is missing, voice if no profile exists, evidence for any review that has none, then the review with the most progress.

Read only. Change nothing.
