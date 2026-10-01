#!/usr/bin/env bash
#
# scripts/build-adapters.sh
#
# Generates every harness adapter from adapters/commands.tsv. An adapter is a
# thin file that tells one AI harness where a Review Harness command lives.
# The logic stays in harness/; adapters only point at it.
#
# Run it after editing commands.tsv, adapters/standalone/PREAMBLE.md,
# harness/principles.md, harness/workflows/review.md or anything in
# harness/formats/. It is deterministic: the same inputs give the same bytes,
# so running it twice in a row changes nothing.
#
# Directories this script owns. It overwrites the files listed here and removes
# any file in them that belongs to a command or format no longer listed, so do
# not keep hand-written files in these directories:
#
#   .agents/skills/<name>/SKILL.md      Cursor, Codex CLI
#   .claude/skills/<name>/SKILL.md      Claude Code, Claude Code plugin, Cline, Cursor (legacy)
#   .opencode/commands/<name>.md        OpenCode
#   .gemini/commands/<name>.toml        Gemini CLI
#   .github/prompts/<name>.prompt.md    GitHub Copilot
#   .windsurf/workflows/<name>.md       Windsurf
#   .roo/commands/<name>.md             Roo Code
#   .kilo/commands/<name>.md            Kilo Code
#   adapters/standalone/<format>.md     paste-in prompts for chat tools with no file access
#   adapters/standalone/README.md       how to use the paste-in prompts
#
# Inputs it reads and never writes: adapters/commands.tsv,
# adapters/standalone/PREAMBLE.md, harness/principles.md,
# harness/workflows/review.md and harness/formats/*.md.
#
# Needs bash 3.2 or newer plus coreutils, sed, awk and grep. Nothing else.
#
# Usage: scripts/build-adapters.sh

set -eu
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

TSV=adapters/commands.tsv
PREAMBLE=adapters/standalone/PREAMBLE.md
FORMATS=harness/formats
STANDALONE=adapters/standalone

# Every directory the script owns, used for the final checks.
OWNED=".agents/skills .claude/skills .opencode/commands .gemini/commands .github/prompts .windsurf/workflows .roo/commands .kilo/commands $STANDALONE"

fail() { printf 'build-adapters: %s\n' "$*" >&2; exit 1; }
emit() { printf '%s\n' "$@"; }

# Commands that only run when the owner names them. Setup creates files and
# folders, so no harness should start it just because a chat mentioned setup.
manual_only() {
  case "$1" in review-setup) return 0 ;; esac
  return 1
}

# ---------------------------------------------------------------------------
# Read commands.tsv into four parallel arrays (bash 3.2 has no associative ones)
# ---------------------------------------------------------------------------

[ -f "$TSV" ] || fail "missing $TSV"
[ -f "$PREAMBLE" ] || fail "missing $PREAMBLE"

expected_header=$(printf 'name\tworkflow\targument_hint\tdescription')
[ "$(head -n 1 "$TSV" | tr -d '\r')" = "$expected_header" ] \
  || fail "$TSV: first line must be the tab separated header: name, workflow, argument_hint, description"

NAMES=(); WORKFLOWS=(); HINTS=(); DESCS=()
n=0

# Every row must have exactly the four columns of the header. A missing tab
# would otherwise shift the description into the hint, and an extra one would
# be dropped in silence.
bad_rows=$(awk 'BEGIN { FS = "\t" }
  { sub(/\r$/, "") }
  NR == 1 || /^[[:space:]]*$/ || /^#/ { next }
  NF != 4 { printf "  line %d has %d column%s: %s\n", NR, NF, (NF == 1 ? "" : "s"), $0 }' "$TSV")
[ -z "$bad_rows" ] || fail "$TSV: every command row needs exactly four tab separated columns (name, workflow, argument_hint, description; leave argument_hint empty between two tabs when there is none)
$bad_rows"

# bash collapses runs of tabs when it splits a line, which would swallow an
# empty argument_hint. awk swaps each tab for the ASCII unit separator (037),
# which bash splits on exactly. awk also drops the header, blank lines,
# comment lines and any trailing CR.
US=$(printf '\037')
while IFS="$US" read -r name workflow hint desc; do
  case "$name" in
    ''|*[!a-z0-9-]*) fail "$TSV: bad command name '$name' (lowercase letters, digits and dashes only)" ;;
  esac
  [ -f "$workflow" ] || fail "$name: workflow file '$workflow' not found"
  [ -n "$desc" ] || fail "$name: description is empty"
  case "$hint$desc" in
    *'"'*) fail "$name: argument_hint and description must not contain double quotes" ;;
  esac
  NAMES[$n]=$name; WORKFLOWS[$n]=$workflow; HINTS[$n]=$hint; DESCS[$n]=$desc
  n=$((n + 1))
done < <(awk 'BEGIN { FS = "\t"; OFS = "\037" }
  { sub(/\r$/, "") }
  NR == 1 || /^[[:space:]]*$/ || /^#/ { next }
  { $1 = $1; print }' "$TSV")
[ "$n" -gt 0 ] || fail "$TSV lists no commands"

known_command() {
  local i=0
  while [ "$i" -lt "$n" ]; do
    [ "${NAMES[$i]}" = "$1" ] && return 0
    i=$((i + 1))
  done
  return 1
}

# Formats: every harness/formats/*.md except README.md, in byte order.
FORMAT_NAMES=""
for f in "$FORMATS"/*.md; do
  [ -f "$f" ] || continue
  name=${f##*/}; name=${name%.md}
  [ "$name" = README ] && continue
  FORMAT_NAMES="$FORMAT_NAMES $name"
done
[ -n "$FORMAT_NAMES" ] || fail "no formats found in $FORMATS"

known_format() {
  local f
  for f in $FORMAT_NAMES; do
    [ "$f" = "$1" ] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Writers. Each takes <name> <workflow> <hint> <desc> and writes one file.
# ---------------------------------------------------------------------------

written=0

# Skills: .agents/skills (Cursor, Codex) and .claude/skills (Claude Code, the
# Claude Code plugin, Cline). Same bytes in both places. Claude Code substitutes
# $ARGUMENTS and resolves ${CLAUDE_PLUGIN_ROOT}; the other harnesses show both
# as written, so the body says what they mean. None of these skills says "read
# AGENTS.md" because every harness that reads a skills directory loads
# AGENTS.md on its own.
write_skill() {  # <dir> <name> <workflow> <hint> <desc>
  local out="$1/$2/SKILL.md"
  mkdir -p "$1/$2"
  {
    emit '---' "name: $2" "description: \"$5\""
    if [ -n "$4" ]; then emit "argument-hint: \"$4\""; fi
    if manual_only "$2"; then emit 'disable-model-invocation: true'; fi
    emit '---' ''
    if [ -n "$4" ]; then
      emit "Follow \`$3\` exactly. Arguments: \$ARGUMENTS. If that line shows a literal placeholder, the arguments are whatever the owner typed after the command."
    else
      emit "Follow \`$3\` exactly."
    fi
    emit '' '`AGENTS.md` and the `harness/` directory sit at the root of this repository. If this skill was installed as a Claude Code plugin, they sit at `${CLAUDE_PLUGIN_ROOT}` instead; read that `AGENTS.md` first. The workspace is the folder you were started in, never a folder inside the plugin.'
  } > "$out"
  written=$((written + 1))
}

# OpenCode: .opencode/commands/<name>.md, invoked as /name, $ARGUMENTS substituted.
write_opencode() {
  local out=".opencode/commands/$1.md" args=""
  if [ -n "$3" ]; then args=" Arguments: \$ARGUMENTS"; fi
  mkdir -p .opencode/commands
  {
    emit '---' "description: \"$4\"" '---' ''
    emit "Read AGENTS.md, then follow \`$2\` exactly.$args"
  } > "$out"
  written=$((written + 1))
}

# Gemini CLI: .gemini/commands/<name>.toml, invoked as /name, {{args}} substituted.
# Descriptions are checked to contain no double quotes, so a basic string is safe.
write_gemini() {
  local out=".gemini/commands/$1.toml" args=""
  if [ -n "$3" ]; then args=" Arguments: {{args}}"; fi
  mkdir -p .gemini/commands
  {
    emit "description = \"$4\"" 'prompt = """'
    emit "Read AGENTS.md, then follow $2 exactly.$args"
    emit '"""'
  } > "$out"
  written=$((written + 1))
}

# GitHub Copilot: .github/prompts/<name>.prompt.md, invoked as /name, arguments as free text.
write_copilot() {
  local out=".github/prompts/$1.prompt.md" args=""
  if [ -n "$3" ]; then args=" Treat any text after the command as the arguments."; fi
  mkdir -p .github/prompts
  {
    emit '---' "name: $1" "description: \"$4\"" 'agent: agent'
    if [ -n "$3" ]; then emit "argument-hint: \"$3\""; fi
    emit '---' ''
    emit "Read AGENTS.md, then follow $2 exactly.$args"
  } > "$out"
  written=$((written + 1))
}

# Windsurf: .windsurf/workflows/<name>.md, invoked as /name, arguments as free text.
write_windsurf() {
  local out=".windsurf/workflows/$1.md"
  mkdir -p .windsurf/workflows
  {
    emit '---' "description: \"$4\"" '---' ''
    emit '1. Read AGENTS.md.' "2. Follow $2 exactly."
    if [ -n "$3" ]; then emit '3. Treat any text after the command as the arguments.'; fi
  } > "$out"
  written=$((written + 1))
}

# Roo Code: .roo/commands/<name>.md, invoked as /name, arguments as free text.
write_roo() {
  local out=".roo/commands/$1.md" args=""
  if [ -n "$3" ]; then args=" Treat any text after the command as the arguments."; fi
  mkdir -p .roo/commands
  {
    emit '---' "description: \"$4\""
    if [ -n "$3" ]; then emit "argument-hint: \"$3\""; fi
    emit '---' ''
    emit "Read AGENTS.md, then follow \`$2\` exactly.$args"
  } > "$out"
  written=$((written + 1))
}

# Kilo Code: .kilo/commands/<name>.md, same shape as Roo: invoked as /name,
# argument-hint in the frontmatter, arguments as free text.
write_kilo() {
  local out=".kilo/commands/$1.md" args=""
  if [ -n "$3" ]; then args=" Treat any text after the command as the arguments."; fi
  mkdir -p .kilo/commands
  {
    emit '---' "description: \"$4\""
    if [ -n "$3" ]; then emit "argument-hint: \"$3\""; fi
    emit '---' ''
    emit "Read AGENTS.md, then follow \`$2\` exactly.$args"
  } > "$out"
  written=$((written + 1))
}

# Standalone: one paste-in prompt per format for chat tools with no file
# access. Preamble, then principles, the review workflow and the format, each
# under a "# File:" heading so the model knows what the workflow refers to.
section() {  # <path>
  emit '' "# File: $1" ''
  awk '{ print }' "$1"
}

write_standalone() {  # <format>
  local out="$STANDALONE/$1.md"
  {
    awk '{ print }' "$PREAMBLE"
    section harness/principles.md
    section harness/workflows/review.md
    section "$FORMATS/$1.md"
  } > "$out"
  written=$((written + 1))
}

write_standalone_readme() {
  local out="$STANDALONE/README.md" name title
  {
    emit '# Standalone prompts' ''
    emit 'One paste-in prompt per review format, for chat tools that cannot read files: a browser chat, a phone app, an internal bot, anything with only a text box.' ''
    emit 'Each file bundles `PREAMBLE.md`, `harness/principles.md`, `harness/workflows/review.md` and one format from `harness/formats/`. Nothing else. Evidence gathering, the voice workflow and the status view need file and tool access, so they are not available this way.' ''
    emit '| File | Review type |' '|---|---|'
    for name in $FORMAT_NAMES; do
      title=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$FORMATS/$name.md")
      emit "| \`$name.md\` | $title |"
    done
    emit '' '## Use' ''
    emit '1. Open the file for the review type you need and copy all of it.'
    emit '2. Paste it as the first message of a new chat, or as the system prompt if the tool has one.'
    emit '3. Say `start`. The assistant asks who the review is about and which language to write in, then interviews you one question at a time.'
    emit '4. If you have a voice profile (`workspace/voice/profile.md`), paste it right after `start`. Without one, the assistant follows the general writing rules only.'
    emit '' '## Resume' ''
    emit 'Every reply that confirms an answer ends with a `Progress` block. To continue later, open a new chat, paste the prompt again, then paste the latest `Progress` block. The assistant picks up from the first unanswered question.' ''
    emit 'Once a draft exists, the `Progress` block also names the current draft number. To resume during drafting or iteration, paste the `Progress` block and the latest draft text together. The assistant continues iterating on that draft; it will ask for the draft if the block says one exists and none was pasted, and it never rebuilds a draft from the notes alone.'
    emit '' '## Regenerate' ''
    emit 'These files are written by `scripts/build-adapters.sh` from `PREAMBLE.md` and the harness files. Edit those and run the script. Changes made directly to a generated file are lost on the next run.'
  } > "$out"
  written=$((written + 1))
}

# ---------------------------------------------------------------------------
# Generate
# ---------------------------------------------------------------------------

i=0
while [ "$i" -lt "$n" ]; do
  name=${NAMES[$i]}; workflow=${WORKFLOWS[$i]}; hint=${HINTS[$i]}; desc=${DESCS[$i]}
  write_skill .agents/skills "$name" "$workflow" "$hint" "$desc"
  write_skill .claude/skills "$name" "$workflow" "$hint" "$desc"
  write_opencode "$name" "$workflow" "$hint" "$desc"
  write_gemini   "$name" "$workflow" "$hint" "$desc"
  write_copilot  "$name" "$workflow" "$hint" "$desc"
  write_windsurf "$name" "$workflow" "$hint" "$desc"
  write_roo      "$name" "$workflow" "$hint" "$desc"
  write_kilo     "$name" "$workflow" "$hint" "$desc"
  i=$((i + 1))
done

nf=0
for name in $FORMAT_NAMES; do
  write_standalone "$name"
  nf=$((nf + 1))
done
write_standalone_readme

# ---------------------------------------------------------------------------
# Remove files for commands or formats that are no longer listed
# ---------------------------------------------------------------------------

removed=0
remove() { rm -f "$1"; removed=$((removed + 1)); printf 'removed stale %s\n' "$1"; }

remove_stale_skills() {  # <dir>
  local d base
  for d in "$1"/*/; do
    [ -d "$d" ] || continue
    base=${d%/}; base=${base##*/}
    known_command "$base" && continue
    [ -f "${d}SKILL.md" ] || continue
    remove "${d}SKILL.md"
    rmdir "$d" 2>/dev/null || true
  done
}

remove_stale_files() {  # <dir> <suffix>
  local f base
  for f in "$1"/*"$2"; do
    [ -f "$f" ] || continue
    base=${f##*/}; base=${base%"$2"}
    known_command "$base" || remove "$f"
  done
}

remove_stale_skills .agents/skills
remove_stale_skills .claude/skills
remove_stale_files .opencode/commands .md
remove_stale_files .gemini/commands .toml
remove_stale_files .github/prompts .prompt.md
remove_stale_files .windsurf/workflows .md
remove_stale_files .roo/commands .md
remove_stale_files .kilo/commands .md

for f in "$STANDALONE"/*.md; do
  [ -f "$f" ] || continue
  base=${f##*/}; base=${base%.md}
  case "$base" in PREAMBLE|README) continue ;; esac
  known_format "$base" || remove "$f"
done

# ---------------------------------------------------------------------------
# Check and report
# ---------------------------------------------------------------------------

EMDASH=$(printf '\342\200\224')
hits=$(grep -rl -- "$EMDASH" $OWNED 2>/dev/null || true)
[ -z "$hits" ] || fail "em dash found in generated output, fix the input files:
$hits"

printf 'build-adapters: wrote %d files (%d commands x 8 harness targets, %d standalone prompts, 1 README), removed %d stale\n' \
  "$written" "$n" "$nf" "$removed"
