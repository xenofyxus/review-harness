#!/usr/bin/env bash
#
# scripts/check.sh
#
# The repository lint. Run it before opening a pull request. CI runs it on
# every push and pull request through .github/workflows/check.yml.
#
# Checks, in order:
#
#   emdash      no em dash character in any file git knows about, except
#               under workspace/ (owner data)
#   vocabulary  none of the words banned in harness/principles.md appear in
#               harness/, docs/, adapters/, examples/, README.md, AGENTS.md
#               or CONTRIBUTING.md. Case-insensitive, whole words, common
#               inflections included (plural, past tense, -ing, -ly). The
#               rule line in principles.md that lists the words is skipped
#               wherever it appears (the standalone prompts embed it). To
#               name banned words on purpose anywhere else, put the marker
#               <!-- vocabulary-list --> on that line.
#   paths       every backtick-quoted repo path in AGENTS.md, README.md,
#               adapters/README.md, docs/*.md and harness/**/*.md exists.
#               Paths with placeholders (<slug>, {{args}}, $VAR, *, ...) are
#               ignored.
#   adapters    scripts/build-adapters.sh, run on a copy of the repo, would
#               change nothing. Catches hand-edited generated files and a
#               commands.tsv that was edited without a rebuild.
#   skills      .claude/skills and .agents/skills are byte-identical
#   scripts     every scripts/*.sh is executable and passes bash -n
#   templates   every file in harness/templates/ is named by a workflow
#   examples    the example reviews follow the writing rules: paragraphs and
#               bold question lines only, no lists, no headers. One title
#               line at the very top is allowed. SKIP when there are no
#               examples yet.
#
# Each check prints one PASS, FAIL or SKIP line, then the offending
# file:line pairs when it fails. The exit code is 1 if anything failed.
#
# Usage: scripts/check.sh [check ...]
#   With no arguments every check runs. Name one or more to run only those,
#   for example: scripts/check.sh vocabulary paths
#
# Needs bash 3.2 or newer plus coreutils, sed, awk, grep and diff. git is
# used to list files when available; without it the check walks the tree.

set -u
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

PRINCIPLES=harness/principles.md
BUILD=scripts/build-adapters.sh
ALL_CHECKS="emdash vocabulary paths adapters skills scripts templates examples"

# Built from bytes so this file stays free of the characters it looks for.
EMDASH=$(printf '\342\200\224')
CURLY_APOSTROPHE=$(printf '\342\200\231')

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

passed=0; failed=0; skipped=0

# Colour on a terminal only, never in CI logs or files.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  GREEN=$(printf '\033[32m'); RED=$(printf '\033[31m'); YELLOW=$(printf '\033[33m')
  BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m'); RESET=$(printf '\033[0m')
else
  GREEN=''; RED=''; YELLOW=''; BOLD=''; DIM=''; RESET=''
fi

pass() { passed=$((passed + 1));   printf '%sPASS%s  %s\n' "$GREEN" "$RESET" "$1"; }
fail() { failed=$((failed + 1));   printf '%sFAIL%s  %s\n' "$RED" "$RESET" "$1"; }
skip() { skipped=$((skipped + 1)); printf '%sSKIP%s  %s\n' "$YELLOW" "$RESET" "$1"; }

# Indents whatever comes in on stdin, for the lines under a FAIL.
details() { sed -e '/^$/d' -e "s/^/      $DIM/" -e "s/\$/$RESET/"; }

usage() {
  printf 'usage: scripts/check.sh [check ...]\n\nchecks: %s\n' "$ALL_CHECKS"
  printf '\nWith no arguments every check runs. NO_COLOR=1 turns colour off.\n'
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Every file in the repo: tracked files plus untracked files that are not
# ignored, so the lint is useful before the first commit too. Without git,
# every file outside .git/.
repo_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard
  else
    find . -type f ! -path './.git/*' | sed 's|^\./||'
  fi
}

# Files the vocabulary rule applies to: the prose, the harness, the adapters
# and the examples. Not the scripts, the workspace or dot directories.
prose_files() {
  local f
  for f in README.md AGENTS.md CONTRIBUTING.md; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  find harness docs adapters examples -type f 2>/dev/null | sort
}

# The line in harness/principles.md that lists the banned words. It is the
# one place the words are allowed without a marker.
VOCABULARY_MARKER='<!-- vocabulary-list -->'
vocabulary_rule_line() {
  awk '/^- No AI vocabulary\. Never:/ { print; exit }' "$PRINCIPLES"
}

# The banned terms, one per line, read from that rule so there is exactly
# one list to maintain.
banned_terms() {
  vocabulary_rule_line \
    | sed 's/^.*Never:[[:space:]]*//' \
    | tr ',' '\n' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\.$//' -e 's/^"//' -e 's/"$//' \
    | grep -v '^$'
}

# Turns one banned term into an extended regex. Single words also match their
# common inflections; phrases match with any spacing and either apostrophe.
# Used with grep -w, so the match must start and end at a word boundary.
term_pattern() {  # <term>
  local t=$1
  case "$t" in
    *' '*) printf '%s' "$t" | sed -e "s/'/('|$CURLY_APOSTROPHE)/g" -e 's/ /[[:space:]]+/g' ;;
    *e)    printf '%s(e|es|ed|ing|ement)?' "${t%e}" ;;
    *y)    printf '%s(y|ys|ies|ied|ying)' "${t%y}" ;;
    *)     printf '%s(s|es|ed|ing|ly|ally|ness|ment)?' "$t" ;;
  esac
}

# ---------------------------------------------------------------------------
# 1. Em dashes
# ---------------------------------------------------------------------------

check_emdash() {
  local f out hits=''
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    case "$f" in workspace/*) continue ;; esac
    if out=$(grep -I -n -H -F -- "$EMDASH" "$f"); then
      hits="$hits$(printf '%s\n' "$out" | cut -d: -f1,2)
"
    fi
  done < <(repo_files)

  if [ -z "$hits" ]; then
    pass "emdash: no em dash character outside workspace/"
  else
    fail "emdash: em dash character found, use a comma, a period or a rewrite"
    printf '%s' "$hits" | details
  fi
}

# ---------------------------------------------------------------------------
# 2. Vocabulary
# ---------------------------------------------------------------------------

check_vocabulary() {
  local rule terms n i t f hit path lineno line matched hits=''
  local TERMS=() PATTERNS=() combined=''

  rule=$(vocabulary_rule_line)
  terms=$(banned_terms)
  if [ -z "$rule" ] || [ -z "$terms" ]; then
    fail "vocabulary: could not read the 'No AI vocabulary' rule from $PRINCIPLES"
    return
  fi

  n=0
  while IFS= read -r t; do
    TERMS[$n]=$t
    PATTERNS[$n]=$(term_pattern "$t")
    combined="$combined${combined:+|}${PATTERNS[$n]}"
    n=$((n + 1))
  done <<EOF
$terms
EOF

  while IFS= read -r f; do
    [ -f "$f" ] || continue
    grep -I -n -H -i -w -E -- "$combined" "$f" 2>/dev/null | while IFS= read -r hit; do
      path=${hit%%:*}; line=${hit#*:}; lineno=${line%%:*}; line=${line#*:}
      [ "$line" = "$rule" ] && continue                        # the rule itself
      case "$line" in *"$VOCABULARY_MARKER"*) continue ;; esac  # marked on purpose
      # Name the terms on the line so the report says what to fix.
      matched=''; i=0
      while [ "$i" -lt "$n" ]; do
        if printf '%s\n' "$line" | grep -q -i -w -E -- "${PATTERNS[$i]}"; then
          matched="$matched${matched:+, }${TERMS[$i]}"
        fi
        i=$((i + 1))
      done
      printf '%s:%s: %s\n' "$path" "$lineno" "$matched"
    done
  done < <(prose_files) > "$TMP/vocabulary"

  hits=$(cat "$TMP/vocabulary")
  if [ -z "$hits" ]; then
    pass "vocabulary: none of the $n banned terms in the prose"
  else
    fail "vocabulary: banned terms found (list in $PRINCIPLES; to name them on purpose add $VOCABULARY_MARKER to the line)"
    printf '%s\n' "$hits" | details
  fi
}

# ---------------------------------------------------------------------------
# 3. Paths
# ---------------------------------------------------------------------------

check_paths() {
  local f token path missing='' checked=0

  while IFS= read -r f; do
    [ -f "$f" ] || continue
    while IFS= read -r token; do
      path=${token#\`}; path=${path%\`}
      path=${path%% *}                          # `scripts/setup.sh -y` names scripts/setup.sh
      path=$(printf '%s' "$path" | sed 's/[.,;:)]*$//')
      case "$path" in
        harness/*|docs/*|scripts/*|adapters/*|examples/*|.claude/*|.claude-plugin/*|.agents/*) ;;
        *) continue ;;
      esac
      case "$path" in
        *'<'*|*'>'*|*'*'*|*'{'*|*'}'*|*'$'*|*'...'*) continue ;;   # placeholders and globs
      esac
      checked=$((checked + 1))
      [ -e "$path" ] || missing="$missing$f: $path
"
    done < <(grep -o '`[^`]*`' "$f")
  done <<EOF
AGENTS.md
README.md
adapters/README.md
$(ls docs/*.md 2>/dev/null)
$(find harness -name '*.md' 2>/dev/null | sort)
EOF

  missing=$(printf '%s' "$missing" | sort -u)
  if [ -z "$missing" ]; then
    pass "paths: all $checked backtick-quoted repo paths exist"
  else
    fail "paths: backtick-quoted paths that do not exist"
    printf '%s\n' "$missing" | details
  fi
}

# ---------------------------------------------------------------------------
# 4. Adapters fresh
# ---------------------------------------------------------------------------

check_adapters() {
  local copy entry out changes

  if [ ! -f "$BUILD" ]; then
    fail "adapters: $BUILD is missing"
    return
  fi

  # Build into a copy of the repo (everything but .git and workspace), then
  # diff the copy against the real tree. Any difference is what a rebuild
  # would change.
  copy="$TMP/build"
  mkdir -p "$copy"
  for entry in .[!.]* *; do
    case "$entry" in .|..|.git|workspace) continue ;; esac
    [ -e "$entry" ] || continue
    cp -R "$entry" "$copy/"
  done

  if ! out=$(cd "$copy" && bash "$BUILD" 2>&1); then
    fail "adapters: $BUILD failed on a copy of the repo"
    printf '%s\n' "$out" | details
    return
  fi

  changes=$(diff -r -q -x .git -x workspace "$copy" . 2>&1 | awk -v copy="$copy" '
    /^Files / {
      sub(/^Files [^ ]+ and \.\//, ""); sub(/ differ$/, "")
      print $0 " would change"; next
    }
    /^Only in / {
      sub(/^Only in /, ""); i = index($0, ": "); dir = substr($0, 1, i - 1); name = substr($0, i + 2)
      if (index(dir, copy) == 1) {
        dir = substr(dir, length(copy) + 2)
        print (dir == "" ? name : dir "/" name) " would be created"
      } else {
        sub(/^\.\/?/, "", dir)
        print (dir == "" ? name : dir "/" name) " would be removed"
      }
      next
    }
    { print }')

  if [ -z "$changes" ]; then
    pass "adapters: generated files match adapters/commands.tsv and the harness"
  else
    fail "adapters: generated files are out of date. Run $BUILD and commit the result"
    printf '%s\n' "$changes" | sort | details
  fi
}

# ---------------------------------------------------------------------------
# 5. Skills identical
# ---------------------------------------------------------------------------

check_skills() {
  local out
  if [ ! -d .claude/skills ] || [ ! -d .agents/skills ]; then
    fail "skills: .claude/skills and .agents/skills must both exist"
    return
  fi
  if out=$(diff -r .claude/skills .agents/skills 2>&1); then
    pass "skills: .claude/skills and .agents/skills are identical"
  else
    fail "skills: .claude/skills and .agents/skills differ. Run $BUILD"
    printf '%s\n' "$out" | grep -E '^(Only in|diff |Files )' | details
  fi
}

# ---------------------------------------------------------------------------
# 6. Scripts executable and syntactically valid
# ---------------------------------------------------------------------------

check_scripts() {
  local f out problems='' count=0
  for f in scripts/*.sh; do
    [ -f "$f" ] || continue
    count=$((count + 1))
    [ -x "$f" ] || problems="$problems$f: not executable (chmod +x $f)
"
    if ! out=$(bash -n "$f" 2>&1); then
      problems="$problems$f: $(printf '%s' "$out" | head -n 1)
"
    fi
  done

  if [ "$count" -eq 0 ]; then
    skip "scripts: no scripts/*.sh to check"
  elif [ -z "$problems" ]; then
    pass "scripts: all $count scripts are executable and parse"
  else
    fail "scripts: not executable or not valid bash"
    printf '%s' "$problems" | details
  fi
}

# ---------------------------------------------------------------------------
# 7. Templates referenced by a workflow
# ---------------------------------------------------------------------------

check_templates() {
  local f name unused='' count=0
  for f in harness/templates/*; do
    [ -f "$f" ] || continue
    count=$((count + 1))
    name=${f#harness/}
    grep -q -F -- "$name" harness/workflows/*.md 2>/dev/null || unused="$unused$f
"
  done

  if [ "$count" -eq 0 ]; then
    skip "templates: harness/templates/ is empty"
  elif [ -z "$unused" ]; then
    pass "templates: all $count templates are named by a workflow"
  else
    fail "templates: not referenced from any file in harness/workflows/"
    printf '%s' "$unused" | details
  fi
}

# ---------------------------------------------------------------------------
# 8. Example reviews obey the writing rules
# ---------------------------------------------------------------------------

check_examples() {
  local dir=examples/demo-workspace/cycles f n line first bad='' count=0

  if [ ! -d "$dir" ]; then
    skip "examples: $dir does not exist yet"
    return
  fi

  for f in "$dir"/*/*/review.md; do
    [ -f "$f" ] || continue
    count=$((count + 1))
    n=0; first=1
    while IFS= read -r line || [ -n "$line" ]; do
      n=$((n + 1))
      case "$line" in ''|'<!--'*) continue ;; esac
      if [ "$first" = 1 ]; then
        first=0
        case "$line" in '# '*) continue ;; esac   # a document title on top is fine
      fi
      case "$line" in
        '**'*) ;;                                  # a question in bold
        '- '*|'* '*|'+ '*|'#'*) bad="$bad$f:$n: list item or header
" ;;
        *) if printf '%s\n' "$line" | grep -q -E '^[0-9]+\. '; then
             bad="$bad$f:$n: numbered list item
"
           fi ;;
      esac
    done < "$f"
  done

  if [ "$count" -eq 0 ]; then
    skip "examples: no review.md under $dir yet"
  elif [ -z "$bad" ]; then
    pass "examples: $count example review(s) use paragraphs and bold questions only"
  else
    fail "examples: lists or headers inside a review, the questions are the structure"
    printf '%s' "$bad" | details
  fi
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

case "${1:-}" in -h|--help) usage; exit 0 ;; esac

run=$ALL_CHECKS
if [ $# -gt 0 ]; then
  run=$*
  for c in $run; do
    case " $ALL_CHECKS " in
      *" $c "*) ;;
      *) printf 'check.sh: unknown check "%s"\n\n' "$c" >&2; usage >&2; exit 2 ;;
    esac
  done
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/review-harness-check.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT

printf '%sReview Harness lint%s  %s\n\n' "$BOLD" "$RESET" "$ROOT"
for c in $run; do
  "check_$c"
done

printf '\n%s%d passed, %d failed, %d skipped%s\n' "$BOLD" "$passed" "$failed" "$skipped" "$RESET"
[ "$failed" -eq 0 ]
