# Harnesses

Every harness reads the same files. `AGENTS.md` is the entrypoint, `harness/` holds all the logic, and each tool gets a thin pointer: a skill, a command file, or nothing at all. Command names are the same everywhere and come from `adapters/commands.tsv`.

**Tested** means a full review has been run in that tool. **Generated, untested** means the files follow the tool's documented convention as of September 2026, but nobody has run a review end to end in it yet. If you do, open an issue and the row changes.

## Support matrix

| Harness | Instructions from | Commands in | Invoke | Status |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md`, imports `AGENTS.md` | `.claude/skills/` | `/review peer priya` | Tested |
| Claude Code plugin | `AGENTS.md` in the plugin root, read by each skill | `.claude/skills/`, installed as a plugin | `/review-harness:review peer priya` | Generated, untested |
| Cursor | `AGENTS.md` | `.agents/skills/` | `/review peer priya` | Generated, untested |
| Codex CLI | `AGENTS.md` | `.agents/skills/` | `$review peer priya` | Generated, untested |
| Gemini CLI | `GEMINI.md`, imports `AGENTS.md` | `.gemini/commands/` | `/review peer priya` | Generated, untested |
| OpenCode | `AGENTS.md` | `.opencode/commands/` | `/review peer priya` | Generated, untested |
| GitHub Copilot | `AGENTS.md` | `.github/prompts/` | `/review peer priya` | Generated, untested |
| Windsurf, Devin | `AGENTS.md` | `.windsurf/workflows/` | `/review peer priya` | Generated, untested |
| Roo Code | `AGENTS.md` | `.roo/commands/` | `/review peer priya` | Generated, untested |
| Kilo Code | `AGENTS.md` | `.kilo/commands/` | `/review peer priya` | Generated, untested |
| Cline | `AGENTS.md` | `.claude/skills/` | ask for the `review` skill with `peer priya` | Generated, untested |
| Aider | `AGENTS.md`, loaded by `.aider.conf.yml` | none | "run the review workflow for peer priya" | Generated, untested |
| Amp, Zed | `AGENTS.md` | none | "run the review workflow for peer priya" | Generated, untested |
| Any chat tool | the pasted `adapters/standalone/<format>.md` | none | paste the file, say `start` | Generated, untested |

## Claude Code

Reads `CLAUDE.md`, one line importing `AGENTS.md`. The five commands are skills in `.claude/skills/<name>/SKILL.md`, each a pointer to one workflow file, with `$ARGUMENTS` carrying what you type after the name. Invoke `/review-setup`, `/review-voice`, `/review-evidence priya`, `/review peer priya`, `/review-status`. Tested.

## Claude Code plugin

The same skills, installed from this repository's marketplace (`.claude-plugin/marketplace.json`). Inside Claude Code:

    /plugin marketplace add xenofyxus/review-harness
    /plugin install review-harness@review-harness

From a shell, the same two steps are `claude plugin marketplace add xenofyxus/review-harness` and `claude plugin install review-harness@review-harness`.

Start Claude Code in the folder that will hold your workspace, not in a clone of this repository. The commands are namespaced, so the first one is `/review-harness:review-setup`; it creates `config.yml` there, in `workspace/` under that folder unless you ask for the folder itself, and the other commands find it from there. Each skill reads `AGENTS.md` from the plugin root (`${CLAUDE_PLUGIN_ROOT}`) and resolves `harness/` next to it, so nothing from the plugin is copied into your folder. `claude plugin validate` warns about the root `CLAUDE.md`; that file is for the clone path and is expected. Generated, untested.

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

Both read a root `AGENTS.md` on their own, so the entrypoint is loaded before any command runs. Commands are Windsurf workflows, files in `.windsurf/workflows/<name>.md`, invoked `/review peer priya`; each one also opens with a line to read `AGENTS.md`, which costs nothing when it is already loaded. Caveats: a Windsurf workflow runs only when you invoke it, the file is capped at 12,000 characters (a pointer file is nowhere near), and newer versions prefer `.devin/` while `.windsurf/` still works. Generated, untested.

## Roo Code

Reads `AGENTS.md`. Commands are `.roo/commands/<name>.md` with `description` and `argument-hint`. Invoke `/review peer priya`. Generated, untested.

## Kilo Code

Reads `AGENTS.md`. Commands are `.kilo/commands/<name>.md` with `description` and `argument-hint`, the same shape as Roo. Invoke `/review peer priya`. Generated, untested.

## Cline

Reads `AGENTS.md` and picks up skills from `.claude/skills/` once skills are switched on in its settings. There is no slash form; ask for the `review` skill with `peer priya`. Generated, untested.

## Aider

Aider does not discover instruction files on its own. The repository ships `.aider.conf.yml` with `read: [AGENTS.md]`, so starting `aider` in the repo root loads the entrypoint read-only. Then say "run the review workflow for peer priya" and it follows the paths in `AGENTS.md`. Generated, untested.

## Amp and Zed

Both read `AGENTS.md` and nothing else. No command files. Say "run review-setup" or "run the review workflow for peer priya". Generated, untested.

## Any chat tool

For a tool with no file access, `adapters/standalone/<format>.md` is one complete paste-in prompt: the preamble, `harness/principles.md`, `harness/workflows/review.md` and that one format. Paste it as the first message of a new chat, or as the system prompt if the tool has one, then say `start`. It asks who the review is about and which language to write in, then interviews you one question at a time. Evidence, voice and status are not available this way; they need file and tool access. To resume, open a new chat, paste the prompt again, then the latest `Progress` block (every reply that confirms an answer or shows a draft ends with one), and the latest draft text if one exists. Generated, untested.

## Adding a harness

Every command file here is built from `adapters/commands.tsv` by `scripts/build-adapters.sh`. There are no template files under `adapters/`; each tool's file format is a `write_<tool>` function in the script. Add one, call it where the other writers are called, add a cleanup line for its directory, run the script twice, and add a row to the matrix above. Keep the adapter thin: a pointer to the workflow file and nothing else. Details in `adapters/README.md`.
