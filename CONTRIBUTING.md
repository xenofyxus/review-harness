# Contributing

Thanks for looking. The harness is plain markdown, so most contributions are edits to text.

## What is welcome

- **New formats** in `harness/formats/`. Keep the structure: questions, hints, checklist.
- **New sources** in `harness/sources/`. Detection, queries, what to write down, what to be careful about.
- **New adapters** for harnesses that read `AGENTS.md` or have a command-file convention. Keep them thin: a pointer to the workflow file, nothing else.
- **Fixes to workflows** where the instructions produced a bad result in practice. Say what happened.
- **Translations** of the formats. Put them in `harness/formats/<lang>/`.

## Rules

- Follow `harness/principles.md` in the docs too. No em dashes anywhere in the repo. No AI vocabulary.
- Logic lives in `harness/`. Adapters point at it. Do not duplicate workflow text into an adapter.
- Nothing personal. No real names, companies or review text. The demo workspace in `examples/` is fictional and stays that way.
- Run `scripts/check.sh` before opening a pull request.

## Testing a change

Copy the repo, run setup with a fictional person, run a review end to end in your harness of choice, and read the draft as the person who would receive it. If it reads like an AI wrote it, the change is not done.
