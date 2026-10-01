# Adapters

An adapter is the small file a harness needs in order to find a Review Harness command. Every adapter says the same thing: with `AGENTS.md` loaded, follow one file under `harness/workflows/`. That is all it does. The questions, the method and the writing rules live in `harness/` and are never copied into an adapter by hand. The standalone prompts bundle them, but the build script does the bundling, so a fix in `harness/` still reaches every harness at once.

## Source of truth

`commands.tsv` lists the five commands, one per line: name, workflow file, argument hint and description. `scripts/build-adapters.sh` reads it and writes every generated file below. Edit the TSV or the harness files, never the generated files; the next run overwrites them.

## Targets

| Where | Harness | How to invoke |
|---|---|---|
| `.claude/skills/<name>/SKILL.md` | Claude Code, Cline, Cursor (legacy path) | `/review peer priya` |
| the same files, installed as a plugin | Claude Code plugin, via `.claude-plugin/plugin.json` | `/review-harness:review peer priya` |
| `.agents/skills/<name>/SKILL.md` | Cursor, Codex CLI | `/review peer priya` in Cursor, `$review peer priya` in Codex |
| `.opencode/commands/<name>.md` | OpenCode | `/review peer priya` |
| `.gemini/commands/<name>.toml` | Gemini CLI | `/review peer priya` |
| `.github/prompts/<name>.prompt.md` | GitHub Copilot in VS Code | `/review peer priya` |
| `.windsurf/workflows/<name>.md` | Windsurf | `/review peer priya` |
| `.roo/commands/<name>.md` | Roo Code | `/review peer priya` |
| `.kilo/commands/<name>.md` | Kilo Code | `/review peer priya` |
| `.aider.conf.yml` (hand-written) | Aider | "run the review workflow for peer priya" |
| `AGENTS.md` alone | Amp, Zed, anything else that reads `AGENTS.md` | "run the review workflow for peer priya" |
| `standalone/<format>.md` | Chat tools with no file access | paste the file, say `start` |

Swap `review` for `review-setup`, `review-evidence`, `review-voice` or `review-status` for the other commands. Arguments are whatever the owner types after the command. Claude Code and OpenCode substitute them for `$ARGUMENTS` in the prompt, Gemini CLI substitutes them for `{{args}}`, and the others (Cursor, Codex, Cline, Copilot, Windsurf, Roo, Kilo) receive them as free text after the command. The workflows accept loose input either way, and the skill files say what to do when `$ARGUMENTS` shows up as a literal placeholder.

Every command file (OpenCode, Gemini CLI, Copilot, Windsurf, Roo, Kilo) opens with "Read AGENTS.md". Only the skill files leave it out, because Claude Code, Cursor, Codex and Cline load `AGENTS.md` themselves (Claude Code through `CLAUDE.md`, which imports it). The skill files instead say where `AGENTS.md` and `harness/` sit when the skills were installed as a Claude Code plugin, and that the workspace is never a folder inside the plugin.

## Regenerate

    scripts/build-adapters.sh

It overwrites every generated file, removes files for commands or formats that are no longer listed, checks the output for em dashes and prints one summary line. Run it twice; the second run must change nothing. It needs bash 3.2, coreutils, sed, awk and grep, nothing else.

## Add a harness

1. Find its convention: which directory it reads, the file format and frontmatter it expects, how a command is invoked and how arguments arrive.
2. In `scripts/build-adapters.sh`, add a `write_<harness>` function next to the others, call it from the per-command loop, add a `remove_stale_files` line for its directory, and list the directory in the header comment and in `OWNED`. There are no template files under `adapters/`; the shape of each generated file lives in its `write_<harness>` function. Keep the body to a pointer at the workflow file.
3. Add a row to the table above and to `docs/harnesses.md`.
4. Run the script twice and check that `git status` shows only the new files.

If the harness reads `AGENTS.md` but has no command convention, there is nothing to generate. Add it to the table with "run the review workflow for ..." as the way in.
