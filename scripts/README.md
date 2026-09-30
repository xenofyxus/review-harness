# Scripts

Four small bash scripts. None of them is required; every one of them has an AI-driven equivalent in `harness/workflows/`. They exist for people who want a plain shell path, and for CI.

| Script | What it does |
|---|---|
| `setup.sh` | Scaffolds `workspace/` without an AI: config, people, cycle folders, progress files. |
| `evidence-github.sh` | Dumps a person's GitHub activity for a window as markdown: merged PRs, open PRs, reviews given, optional PR size stats. |
| `build-adapters.sh` | Regenerates every harness adapter and the standalone prompts from `adapters/commands.tsv` and `harness/`. |
| `check.sh` | Lints the repo: em dashes, vocabulary, broken paths, adapter freshness, identical skills, script syntax, orphan templates, example formatting. |

All four run on macOS bash 3.2 and Linux with coreutils, sed, awk and grep. `evidence-github.sh` also needs the `gh` CLI, authenticated.

## setup.sh

```sh
scripts/setup.sh          # interactive
scripts/setup.sh -h       # usage, including the RH_* variables

# non-interactive, for scripts and tests
RH_NAME="Maya Lindqvist" RH_ROLE="Senior Backend Engineer" RH_COMPANY="Northwind Labs" \
RH_CYCLE=2026-h2 RH_PEOPLE="Tomas Berg|manager|Backend Team Lead;Priya Nair|peer|Backend Engineer" \
scripts/setup.sh -y
```

Never overwrites an existing person, progress or review file. On an existing workspace it offers to add a cycle or a person. Warns if the repository it sits in is public.

## evidence-github.sh

```sh
scripts/evidence-github.sh -u mayalq -o northwind-labs -s 2026-03-15 > workspace/cycles/2026-h2/self/evidence-raw.md
scripts/evidence-github.sh -u mayalq -o northwind-labs -s 2026-03-15 -z northwind-labs/api   # add PR size stats for one repo
```

Progress goes to stderr, markdown to stdout. The recipes it runs are the ones in `harness/sources/github.md`.

## build-adapters.sh

```sh
scripts/build-adapters.sh
```

Rewrites `.agents/skills/`, `.claude/skills/`, `.opencode/commands/`, `.gemini/commands/`, `.github/prompts/`, `.windsurf/workflows/`, `.roo/commands/`, `.kilo/commands/` and `adapters/standalone/`. Run it after changing `adapters/commands.tsv`, `harness/principles.md`, `harness/workflows/review.md` or a format, then commit the result. Stale files for removed commands are deleted.

## check.sh

```sh
scripts/check.sh                    # all checks
scripts/check.sh vocabulary paths   # a subset
NO_COLOR=1 scripts/check.sh         # plain output
```

Exit code is non-zero on any failure. CI runs it on every push and pull request (`.github/workflows/check.yml`). A line that has to name banned words on purpose can carry `<!-- vocabulary-list -->` to be skipped.
