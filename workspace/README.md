# Workspace

Everything private lives here: who you are, who you review, how you write, and the reviews themselves.

This folder is empty until you run setup. Ask your AI harness to run `review-setup` (Claude Code: `/review-setup`), or run `scripts/setup.sh` for a plain scaffold without an AI.

```
config.yml            who you are, who you review, the current cycle
voice/profile.md      how you write, built from voice/samples/
voice/samples/        past reviews and other writing you did
people/<slug>.md      background on each person
formats/<type>.md     optional overrides of the built-in question sets
cycles/<cycle>/       one folder per review: progress.md, evidence.md, notes.md, review.md
```

**Keep this private.** Reviews contain candid judgments about real colleagues. Use a private repository, or uncomment the `workspace/**` lines in `.gitignore` to keep it out of git entirely.
