# Harnesses

Every harness reads the same files. `AGENTS.md` is the entrypoint, `harness/` holds all the logic, and each tool gets a thin pointer: a skill, a command file, or nothing at all. Command names are the same everywhere and come from `adapters/commands.tsv`.

**Tested** means a full review has been run in that tool. **Generated, untested** means the files follow the tool's documented convention as of September 2026, but nobody has run a review end to end in it yet. If you do, open an issue and the row changes.

## Support matrix

| Harness | Instructions from | Commands in | Invoke | Status |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md`, imports `AGENTS.md` | `.claude/skills/` | `/review peer priya` | Tested |
| Claude Code plugin | `.claude-plugin/plugin.json` | `.claude/skills/` | `/review-harness:review peer priya` | Generated, untested |
| Cursor | `AGENTS.md` | `.agents/skills/` | `/review peer priya` | Generated, untested |
| Codex CLI | `AGENTS.md` | `.agents/skills/` | `$review peer priya` | Generated, untested |
| Gemini CLI | `GEMINI.md`, imports `AGENTS.md` | `.gemini/commands/` | `/review peer priya` | Generated, untested |
| OpenCode | `AGENTS.md` | `.opencode/commands/` | `/review peer priya` | Generated, untested |
| GitHub Copilot | `AGENTS.md` | `.github/prompts/` | `/review peer priya` | Generated, untested |
| Windsurf, Devin | the workflow file points at `AGENTS.md` | `.windsurf/workflows/` | `/review peer priya` | Generated, untested |
| Roo Code | `AGENTS.md` | `.roo/commands/` | `/review peer priya` | Generated, untested |
| Kilo Code | `AGENTS.md` | `.kilo/commands/` | `/review peer priya` | Generated, untested |
| Cline | `AGENTS.md` | `.claude/skills/` | ask for the skill by name | Generated, untested |
| Aider | `.aider.conf.yml` loads `AGENTS.md` | none | plain English | Generated, untested |
| Amp, Zed | `AGENTS.md` | none | plain English | Generated, untested |
| Any chat tool | pasted from `adapters/standalone/` | none | plain English | Generated, untested |


## Claude Code

Reads `CLAUDE.md`, one line importing `AGENTS.md`. The five commands are skills in `.claude/skills/<name>/SKILL.md`, each a pointer to one workflow file, with `$ARGUMENTS` carrying what you type after the name. Invoke `/review-setup`, `/review-voice`, `/review-evidence priya`, `/review peer priya`, `/review-status`.

As a plugin, install from this repository's marketplace (`.claude-plugin/marketplace.json`) and the commands are namespaced: `/review-harness:review peer priya`. The skills then read `${CLAUDE_PLUGIN_ROOT}/AGENTS.md` first and resolve `harness/` from there; your workspace stays in the folder you run Claude Code in. Template: Tested. Plugin install: Generated, untested.

## Cursor

Reads `AGENTS.md`. Cursor folded commands into skills, so they live in `.agents/skills/<name>/SKILL.md`, with `.claude/skills/` still read as a legacy location. Invoke `/review peer priya`; arguments are passed as free text after the name. Generated, untested.

## Codex CLI

Reads `AGENTS.md` and `.agents/skills/`. Codex has no repo-local prompt files, so skills are the whole story. Invoke `$review peer priya`, or describe what you want and it finds the skill. Generated, untested.

## Gemini CLI

Reads `GEMINI.md`, which is `@./AGENTS.md` and nothing else, so no extra configuration is needed. Commands are `.gemini/commands/<name>.toml` with a `description` and a `prompt` using `{{args}}`. Invoke `/review peer priya`. Generated, untested.

## OpenCode

Reads `AGENTS.md`. Commands are `.opencode/commands/<name>.md` with a `description` in the frontmatter and `$ARGUMENTS` in the body. Invoke `/review peer priya`. Generated, untested.

## GitHub Copilot

Reads `AGENTS.md` natively. Commands are prompt files in `.github/prompts/<name>.prompt.md` with `name`, `description`, `agent: agent` and `argument-hint`. Invoke `/review peer priya` in the VS Code chat. Caveat: prompt files are deprecated for the cloud coding agent, so use them with the local agent in VS Code. Generated, untested.

## Windsurf and Devin Desktop

Commands are workflows in `.windsurf/workflows/<name>.md`, invoked `/review peer priya`. Each one opens by pointing at `AGENTS.md`. Caveats: workflows run only when you invoke them, they are capped at 12,000 characters (a pointer file is nowhere near), and newer versions prefer `.devin/` while `.windsurf/` still works. Generated, untested.

## Roo Code

Reads `AGENTS.md`. Commands are `.roo/commands/<name>.md` with `description` and `argument-hint`. Invoke `/review peer priya`. Generated, untested.

## Kilo Code

Reads `AGENTS.md`. Commands are `.kilo/commands/<name>.md` with a `description`. Invoke `/review peer priya`. Generated, untested.

## Cline

Reads `AGENTS.md` and picks up skills from `.claude/skills/`. There is no slash form; name the skill in the chat, for example "use the review skill for peer priya". Generated, untested.

## Aider

Aider does not discover instruction files on its own. The repository ships `.aider.conf.yml` with `read: [AGENTS.md]`, so starting `aider` in the repo root loads the entrypoint read-only. Then say "run the review workflow for peer priya" and it follows the paths in `AGENTS.md`. Generated, untested.

## Amp and Zed

Both read `AGENTS.md` and nothing else. No command files. Say "run review-setup" or "run the review workflow for peer priya". Generated, untested.

## Any chat tool

For a tool with no file conventions, `adapters/standalone/` holds what to paste: the entrypoint plus a pointer to the workflow you want. Paste it with the workflow file, `harness/principles.md` and the format, then say "run the review workflow for peer priya". It is the fallback, not the recommended path. Generated, untested.

## Adding a harness

Every command file here is built from `adapters/commands.tsv` by `scripts/build-adapters.sh`. Add a template for the new tool's file format under `adapters/`, add a case to the script, run it. Keep the adapter thin: a pointer to the workflow file and nothing else. Details in `adapters/README.md`.
