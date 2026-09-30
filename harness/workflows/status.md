# Workflow: status

Show where every review in the current cycle stands.

1. Read `<workspace>/config.yml`. Take the current cycle and the `reviews:` list.
2. For each review, read `cycles/<cycle>/<slug>/progress.md` if it exists. Note the status, how many questions are ticked, whether `evidence.md` exists, when it was last updated.
3. Also list any folders under `cycles/<cycle>/` that are not in `config.yml`, so nothing is forgotten.
4. Present one table: person, format, status, questions answered, evidence, last updated.
5. Suggest the next thing to do in one line. Prefer: setup if config is missing, voice if no profile exists, evidence for any review that has none, then the review with the most progress.

Read only. Change nothing.
