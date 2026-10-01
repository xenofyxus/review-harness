#!/usr/bin/env bash
#
# Review Harness: scaffold a workspace without an AI.
#
# Produces the same files as harness/workflows/setup.md, from the templates in
# harness/templates/. Nothing here is smarter than the workflow; it is for people
# who prefer a plain script, or who want a workspace before opening a harness.
#
# Usage:
#   scripts/setup.sh            interactive
#   scripts/setup.sh -y         take defaults, read answers from the environment
#   scripts/setup.sh -h         this help
#
# Environment (read as defaults in both modes, required with -y where marked):
#   RH_NAME      your name (required with -y)
#   RH_ROLE      your role
#   RH_COMPANY   your company
#   RH_LANG      language for reviews, default en
#   RH_CYCLE     cycle name, default from today's date, e.g. 2026-h2
#                (a-z, 0-9, dots, underscores and dashes; cannot start with a dot)
#   RH_PEOPLE    "Name|relation|role;Name|relation|role[|format]"
#                relation is manager, peer or report; format defaults to the relation
#   RH_SELF      y or n, self review this cycle, default y
#
# With an existing workspace/config.yml the script only adds: a new cycle
# (RH_CYCLE, or the menu) or new people (RH_PEOPLE, or the menu). Existing files
# are never overwritten.
#
# Interactive mode stops with an error when stdin runs out, so a run without a
# terminal needs -y.
#
# Portable: bash 3.2 or newer, coreutils, sed. git and gh are used for the
# privacy check only if they happen to be installed.

set -eu

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR-}" ] && [ "${TERM-}" != dumb ]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' GREEN=$'\033[32m' YELLOW=$'\033[33m' RED=$'\033[31m' RESET=$'\033[0m'
else
  BOLD='' DIM='' GREEN='' YELLOW='' RED='' RESET=''
fi

say()     { printf '%s\n' "$*"; }
heading() { printf '\n%s%s%s\n' "$BOLD" "$*" "$RESET"; }
warn()    { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
die()     { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
  # The comment block at the top of this file, minus the leading "# "
  sed -n '3,/^$/p' "${BASH_SOURCE[0]}" | sed -e 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HARNESS=$ROOT/harness
WORKSPACE=$ROOT/workspace
CONFIG=$WORKSPACE/config.yml
TEMPLATES=$HARNESS/templates

[ -d "$TEMPLATES" ] || die "no harness/templates/ next to $SCRIPT_DIR; run this from a Review Harness checkout"

rel() { printf '%s' "${1#$ROOT/}"; }

CREATED=0
KEPT=0

# ---------------------------------------------------------------------------
# Small string helpers
# ---------------------------------------------------------------------------

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

lower() { printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }

# Escape a value for the replacement side of sed s~...~...~
sed_esc() { printf '%s\n' "$1" | sed -e 's/[\\&~]/\\&/g'; }

# True when a bare YAML scalar would be read as a number: integers, floats,
# exponents, hex, octal, and the YAML 1.1 spellings with underscores.
yaml_numeric() {
  local re
  case "$1" in *[0-9]*) ;; *) return 1 ;; esac
  re='^[-+]?([0-9_]+|[0-9_]*\.[0-9_]*)([eE][-+]?[0-9]+)?$'
  [[ $1 =~ $re ]] && return 0
  re='^[-+]?0[xX][0-9a-fA-F_]+$'
  [[ $1 =~ $re ]] && return 0
  re='^[-+]?0[oO]?[0-7_]+$'
  [[ $1 =~ $re ]] && return 0
  return 1
}

# Print a YAML scalar, quoted only when a bare value would be misread: empty,
# special characters, leading or trailing blanks, a YAML 1.1 boolean or null
# (yes, no, on, off, y, n, true, false, ~) or anything that looks like a number.
yaml_str() {
  local v=$1 specials=':#[]{},&*!|>%@"'"'"'`'
  if [ -z "$v" ] || [[ $v == *["$specials"]* ]] || [[ $v == ' '* ]] || [[ $v == *' ' ]] \
     || [[ $v == -* ]] || [[ $v == \?* ]] || yaml_numeric "$v"; then
    v=${v//\\/\\\\}
    v=${v//\"/\\\"}
    printf '"%s"' "$v"
  else
    case "$(lower "$v")" in
      true|false|yes|no|on|off|y|n|null|'~'|.inf|+.inf|.nan) printf '"%s"' "$v" ;;
      *) printf '%s' "$v" ;;
    esac
  fi
}

# key: value, or just key: when the value is empty (matches the template style)
kv() {
  local indent=$1 key=$2 value=$3
  if [ -z "$value" ]; then
    printf '%s%s:\n' "$indent" "$key"
  else
    printf '%s%s: %s\n' "$indent" "$key" "$(yaml_str "$value")"
  fi
}

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------

YES=0

# read_answer VAR: one line from stdin into VAR. Running out of input is fatal,
# so a closed stdin cannot loop a required question forever. A last line with
# no newline still counts.
read_answer() {
  local __line=''
  if ! IFS= read -r __line && [ -z "$__line" ]; then
    printf '\n' >&2
    die "no more input on stdin. For a run without a terminal use -y and set RH_NAME, RH_PEOPLE and friends (see -h)."
  fi
  printf -v "$1" '%s' "$__line"
}

# ask VAR "prompt" "default"   (default is used silently with -y)
ask() {
  local __var=$1 __prompt=$2 __default=${3-} __answer
  if [ "$YES" = 1 ]; then
    __answer=$__default
  else
    if [ -n "$__default" ]; then
      printf '%s [%s]: ' "$__prompt" "$__default"
    else
      printf '%s: ' "$__prompt"
    fi
    read_answer __answer
    __answer=$(trim "$__answer")
    [ -n "$__answer" ] || __answer=$__default
  fi
  __answer=$(trim "$__answer")
  printf -v "$__var" '%s' "$__answer"
}

# ask_required VAR "prompt" "default"   (loops until non-empty; dies with -y)
ask_required() {
  local __var=$1
  while :; do
    ask "$@"
    [ -n "${!__var}" ] && return 0
    [ "$YES" = 1 ] && die "$2 is required (set RH_NAME and friends, see -h)"
    say "  Please give a value."
  done
}

# ask_yn "prompt" default   -> exit status 0 for yes. The default is any
# spelling of yes or no (y, yes, n, no, ...); anything else counts as no.
ask_yn() {
  local prompt=$1 def ans
  case "$(lower "$(trim "$2")")" in y|yes|true|on|1) def=y ;; *) def=n ;; esac
  if [ "$YES" = 1 ]; then
    ans=$def
  else
    if [ "$def" = y ]; then printf '%s [Y/n]: ' "$prompt"; else printf '%s [y/N]: ' "$prompt"; fi
    read_answer ans
    ans=$(trim "$ans")
    [ -n "$ans" ] || ans=$def
  fi
  case "$(lower "$ans")" in y|yes) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# Slugs: lowercase first name, ASCII only, deduplicated with surname letters
# ---------------------------------------------------------------------------

USED_SLUGS=" self "

slug_in_use() {
  case "$USED_SLUGS" in *" $1 "*) return 0 ;; esac
  return 1
}

slug_reserve() { USED_SLUGS="$USED_SLUGS$1 "; }

# Transliterate the common accented letters, then keep only a-z0-9.
slugify() {
  local s=$1
  s=${s//å/a}; s=${s//Å/a}; s=${s//ä/a}; s=${s//Ä/a}; s=${s//á/a}; s=${s//Á/a}
  s=${s//à/a}; s=${s//À/a}; s=${s//â/a}; s=${s//Â/a}; s=${s//ã/a}; s=${s//Ã/a}
  s=${s//æ/ae}; s=${s//Æ/ae}; s=${s//ç/c}; s=${s//Ç/c}
  s=${s//é/e}; s=${s//É/e}; s=${s//è/e}; s=${s//È/e}; s=${s//ê/e}; s=${s//Ê/e}; s=${s//ë/e}; s=${s//Ë/e}
  s=${s//í/i}; s=${s//Í/i}; s=${s//ì/i}; s=${s//Ì/i}; s=${s//î/i}; s=${s//Î/i}; s=${s//ï/i}; s=${s//Ï/i}
  s=${s//ñ/n}; s=${s//Ñ/n}
  s=${s//ö/o}; s=${s//Ö/o}; s=${s//ø/o}; s=${s//Ø/o}; s=${s//ó/o}; s=${s//Ó/o}
  s=${s//ò/o}; s=${s//Ò/o}; s=${s//ô/o}; s=${s//Ô/o}; s=${s//õ/o}; s=${s//Õ/o}
  s=${s//ú/u}; s=${s//Ú/u}; s=${s//ù/u}; s=${s//Ù/u}; s=${s//û/u}; s=${s//Û/u}; s=${s//ü/u}; s=${s//Ü/u}
  s=${s//ý/y}; s=${s//Ý/y}; s=${s//ÿ/y}; s=${s//ß/ss}
  printf '%s' "$s" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cd 'a-z0-9'
}

# make_slug "Full Name" -> sets MADE_SLUG to a slug not yet in USED_SLUGS and reserves it.
# (Sets a variable rather than printing, so the reservation survives; $(...) would lose it.)
MADE_SLUG=''
make_slug() {
  local full first rest base letters candidate i n
  full=$(trim "$1")
  first=${full%% *}
  rest=${full#"$first"}
  base=$(slugify "$first")
  [ -n "$base" ] || base=person
  letters=$(slugify "$rest")
  candidate=$base
  i=0
  while slug_in_use "$candidate"; do
    i=$((i + 1))
    if [ "$i" -le "${#letters}" ]; then
      candidate=$base${letters:0:$i}
    else
      n=$((i - ${#letters} + 1))
      candidate=$base$letters$n
    fi
  done
  slug_reserve "$candidate"
  MADE_SLUG=$candidate
}

# Cycle names are folder names under cycles/: lowercase, a-z 0-9 . _ - and
# never starting with a dot, so "." and ".." cannot escape the folder.
slugify_cycle() {
  local s
  s=$(printf '%s' "$(trim "$1")" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr ' ' '-' | LC_ALL=C tr -cd 'a-z0-9._-')
  s=${s#"${s%%[!.]*}"}
  printf '%s' "$s"
}

# True for a cleaned cycle name that is safe to use as a folder.
valid_cycle() {
  [ -n "$1" ] || return 1
  case "$1" in .*) return 1 ;; esac
  return 0
}

CYCLE_RULE="a cycle name uses a-z, 0-9, dots, underscores and dashes, and cannot start with a dot"

# ask_cycle VAR "default": asks for a cycle name, cleans it, and insists on a
# usable one. Loops interactively; dies with -y.
ask_cycle() {
  local __var=$1 __default=$2 __raw __clean
  while :; do
    ask __raw "Cycle name" "$__default"
    __clean=$(slugify_cycle "$__raw")
    if valid_cycle "$__clean"; then
      printf -v "$__var" '%s' "$__clean"
      return 0
    fi
    [ "$YES" = 1 ] && die "cycle name '$__raw' is not usable: $CYCLE_RULE"
    say "  Not a usable cycle name: $CYCLE_RULE."
  done
}

default_cycle() {
  local y m
  y=$(date +%Y)
  m=$(date +%m)
  m=${m#0}
  if [ "$m" -le 6 ]; then printf '%s-h1' "$y"; else printf '%s-h2' "$y"; fi
}

# ---------------------------------------------------------------------------
# Formats
# ---------------------------------------------------------------------------

# The workspace copy wins over the harness copy, as in the review workflow.
format_file() {
  if [ -f "$WORKSPACE/formats/$1.md" ]; then
    printf '%s' "$WORKSPACE/formats/$1.md"
  elif [ -f "$HARNESS/formats/$1.md" ]; then
    printf '%s' "$HARNESS/formats/$1.md"
  else
    return 1
  fi
}

list_formats() {
  local f names=""
  for f in "$HARNESS"/formats/*.md "$WORKSPACE"/formats/*.md; do
    [ -f "$f" ] || continue
    f=${f##*/}
    f=${f%.md}
    [ "$f" = README ] && continue
    case " $names " in *" $f "*) ;; *) names="$names $f" ;; esac
  done
  printf '%s' "$(trim "$names")" | tr ' ' ','  | sed -e 's/,/, /g'
}

format_title() { sed -n '1s/^# *//p' "$1"; }

# The questions under "## Questions", shortened to their first clause (cut at
# the first period or question mark), as the setup workflow says. Built-in
# formats number them; a workspace override may use "- " bullets instead.
format_questions() {
  sed -n '/^## Questions/,/^## /p' "$1" \
    | sed -n -e 's/^[0-9][0-9]*\. *//p' -e t -e 's/^- *//p' \
    | sed -e 's/[.?].*$//' -e 's/[[:space:]]*$//'
}

default_format_for() {
  case "$1" in
    manager) printf 'manager' ;;
    peer)    printf 'peer' ;;
    report)  printf 'report' ;;
    self)    printf 'self' ;;
    *)       printf '%s' "$1" ;;
  esac
}

valid_relation() {
  case "$1" in manager|peer|report) return 0 ;; esac
  return 1
}

# ---------------------------------------------------------------------------
# Writers. Every file goes through write_if_absent; nothing is overwritten.
# ---------------------------------------------------------------------------

# write_if_absent PATH   (content on stdin)
write_if_absent() {
  local path=$1
  if [ -e "$path" ]; then
    cat >/dev/null
    printf '  %skept%s     %s\n' "$DIM" "$RESET" "$(rel "$path")"
    KEPT=$((KEPT + 1))
  else
    mkdir -p "$(dirname "$path")"
    cat >"$path"
    printf '  %screated%s  %s\n' "$GREEN" "$RESET" "$(rel "$path")"
    CREATED=$((CREATED + 1))
  fi
}

# render_person NAME SLUG RELATION ROLE
# Substitutes into harness/templates/person.md so new lines in the template
# (the **Handles:** line, the placeholder paragraphs) come through as they are.
# The script does not collect handles, so their placeholders are left blank;
# the free-text prompts stay for the owner to fill in.
render_person() {
  sed -e "s~<Name>~$(sed_esc "$1")~g" \
      -e "s~<slug>~$(sed_esc "$2")~g" \
      -e "s~<manager | peer | report>~$(sed_esc "$3")~g" \
      -e "s~<role, team>~$(sed_esc "$4")~g" \
      -e '/^\*\*Handles:\*\*/ s~<[^>]*>~~g' \
      -e '/^\*\*Worked together since:\*\*/ s~<[^>]*>~~g' \
      "$TEMPLATES/person.md"
}

# render_cycle_readme CYCLE
render_cycle_readme() {
  sed -e "s~<cycle>~$(sed_esc "$1")~g" "$TEMPLATES/cycle-readme.md"
}

# render_progress TITLE NAME SLUG FORMAT CYCLE QUESTIONS
render_progress() {
  local qlist=$6 emitted=0 line n q
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      [0-9]*". [ ] <question"*)
        if [ "$emitted" -eq 0 ]; then
          emitted=1
          n=0
          while IFS= read -r q; do
            [ -n "$q" ] || continue
            n=$((n + 1))
            printf '%d. [ ] %s\n' "$n" "$q"
          done <<<"$qlist"
        fi
        ;;
      '<'*) printf 'Nothing yet.\n' ;;
      *) printf '%s\n' "$line" ;;
    esac
  done <"$TEMPLATES/progress.md" \
    | sed -e "s~<Format title>~$(sed_esc "$1")~g" \
          -e "s~<Name>~$(sed_esc "$2")~g" \
          -e "s~<slug>~$(sed_esc "$3")~g" \
          -e "s~<type>~$(sed_esc "$4")~g" \
          -e "s~<cycle>~$(sed_esc "$5")~g"
}

render_voice_readme() {
  cat <<'EOF'
# Voice samples

Drop past reviews and other writing here, then run the voice workflow.
This folder and any notes.md are yours to fill by hand; the voice workflow writes voice/profile.md.
EOF
}

# write_person NAME SLUG RELATION ROLE
write_person() {
  local content
  content=$(render_person "$1" "$2" "$3" "$4")
  write_if_absent "$WORKSPACE/people/$2.md" <<<"$content"
}

# write_cycle_readme CYCLE
write_cycle_readme() {
  local content
  content=$(render_cycle_readme "$1")
  write_if_absent "$WORKSPACE/cycles/$1/README.md" <<<"$content"
}

# write_progress NAME SLUG FORMAT CYCLE
write_progress() {
  local name=$1 slug=$2 format=$3 cycle=$4 file title questions content
  file=$(format_file "$format") || { warn "no format '$format' for $slug, skipped cycles/$cycle/$slug/progress.md"; return 0; }
  title=$(format_title "$file")
  questions=$(format_questions "$file")
  content=$(render_progress "$title" "$name" "$slug" "$format" "$cycle" "$questions")
  write_if_absent "$WORKSPACE/cycles/$cycle/$slug/progress.md" <<<"$content"
}

write_voice_readme() {
  local content
  content=$(render_voice_readme)
  write_if_absent "$WORKSPACE/voice/samples/README.md" <<<"$content"
}

# ---------------------------------------------------------------------------
# config.yml: render (fresh), load, and edit (extend)
# ---------------------------------------------------------------------------

# Answers for a fresh setup
OWNER_NAME='' OWNER_ROLE='' OWNER_COMPANY='' OWNER_LANG='' CYCLE=''
NEW_NAME=() NEW_SLUG=() NEW_REL=() NEW_ROLE=() NEW_FORMAT=()
SELF_REVIEW=0

# Comments sit at column 27 in the template; keep that.
aligned() { printf '%-26s%s\n' "$1" "$2"; }

render_config() {
  local i=0
  cat <<'EOF'
# Review Harness workspace config.
# Edit by hand or run the setup workflow. Slugs are lowercase, used as folder names.

me:
EOF
  kv '  ' name "$OWNER_NAME"
  say '  slug: self'
  kv '  ' role "$OWNER_ROLE"
  kv '  ' company "$OWNER_COMPANY"
  aligned "  language: $(yaml_str "$OWNER_LANG")" '# language the reviews are written in (en, sv, de, ...)'
  cat <<'EOF'
  handles:                # optional, used by the evidence workflow
    github:
    gitlab:
    slack:                # your Slack member ID, e.g. U0123ABCD
    linear:               # your Linear display name or email
    jira:

EOF
  aligned "cycle: $(yaml_str "$CYCLE")" '# current cycle, a folder under cycles/'
  say ''
  if [ "${#NEW_NAME[@]}" -eq 0 ]; then
    say 'people: []'
  else
    say 'people:'
    while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
      kv '  - ' name "${NEW_NAME[$i]}"
      say "    slug: ${NEW_SLUG[$i]}"
      if [ "$i" -eq 0 ]; then
        aligned "    relation: ${NEW_REL[$i]}" '# manager | peer | report'
      else
        say "    relation: ${NEW_REL[$i]}"
      fi
      kv '    ' role "${NEW_ROLE[$i]}"
      i=$((i + 1))
    done
  fi
  say ''
  if [ "$SELF_REVIEW" -eq 0 ] && [ "${#NEW_NAME[@]}" -eq 0 ]; then
    aligned 'reviews: []' '# what needs writing this cycle'
  else
    aligned 'reviews:' '# what needs writing this cycle'
    if [ "$SELF_REVIEW" -eq 1 ]; then
      say '  - person: self'
      aligned '    format: self' '# a file in harness/formats/ or workspace/formats/'
    fi
    i=0
    while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
      say "  - person: ${NEW_SLUG[$i]}"
      if [ "$SELF_REVIEW" -eq 0 ] && [ "$i" -eq 0 ]; then
        aligned "    format: ${NEW_FORMAT[$i]}" '# a file in harness/formats/ or workspace/formats/'
      else
        say "    format: ${NEW_FORMAT[$i]}"
      fi
      i=$((i + 1))
    done
  fi
  cat <<'EOF'

evidence:
  window_months: 6
  sources: [github, linear, slack, notes]   # tried in this order, skipped if unavailable; add gitlab and jira if you use them
  github_orgs: []
  gitlab_groups: []
EOF
}

# What load_config fills in
CFG_NAME='' CFG_ROLE='' CFG_COMPANY='' CFG_LANG='' CFG_CYCLE=''
P_NAME=() P_SLUG=() P_REL=() P_ROLE=()
R_PERSON=() R_FORMAT=()

# Strip surrounding quotes from a YAML scalar
unquote() {
  local v=$1
  case "$v" in
    \"*\") v=${v#\"}; v=${v%\"}; v=${v//\\\"/\"}; v=${v//\\\\/\\} ;;
    \'*\') v=${v#\'}; v=${v%\'}; v=${v//\'\'/\'} ;;
  esac
  printf '%s' "$v"
}

# Drop a trailing "   # comment" from a config line. A " #" inside a quoted
# value ("Maya # 1") is part of the value and stays.
strip_comment() {
  local line=$1 val v re
  case "$line" in *'#'*) ;; *) printf '%s' "$line"; return 0 ;; esac
  case "$(trim "$line")" in \#*) return 0 ;; esac
  case "$line" in
    *:*)
      val=${line#*:}
      v=${val#"${val%%[![:space:]]*}"}
      re='^"([^"\\]|\\.)*"'
      if [[ $v == \"* ]] && [[ $v =~ $re ]]; then
        printf '%s' "${line%%:*}:${val%%"$v"}${BASH_REMATCH[0]}"
        return 0
      fi
      re="^'([^']|'')*'"
      if [[ $v == \'* ]] && [[ $v =~ $re ]]; then
        printf '%s' "${line%%:*}:${val%%"$v"}${BASH_REMATCH[0]}"
        return 0
      fi
      ;;
  esac
  printf '%s' "${line%%[[:space:]]#*}"
}

# A line-by-line reader for the shape of harness/templates/config.yml.
# It does not parse YAML in general; it reads the file the setup workflow writes.
load_config() {
  local line t section='' depth key val pi=-1 ri=-1
  CFG_NAME='' CFG_ROLE='' CFG_COMPANY='' CFG_LANG='' CFG_CYCLE=''
  P_NAME=() P_SLUG=() P_REL=() P_ROLE=()
  R_PERSON=() R_FORMAT=()
  while IFS= read -r line || [ -n "$line" ]; do
    line=$(strip_comment "$line")
    t=$(trim "$line")
    case "$t" in ''|\#*) continue ;; esac
    case "$line" in
      [A-Za-z_]*:*)
        section=${line%%:*}
        val=$(trim "${line#*:}")
        [ "$section" = cycle ] && CFG_CYCLE=$(unquote "$val")
        continue
        ;;
    esac
    depth=${line%%[![:space:]]*}
    depth=${#depth}
    case "$t" in
      '- '*) t=${t#- }; t=$(trim "$t"); [ "$section" = people ] && pi=$((pi + 1)); [ "$section" = reviews ] && ri=$((ri + 1)) ;;
    esac
    key=${t%%:*}
    val=$(unquote "$(trim "${t#*:}")")
    case "$section:$depth:$key" in
      me:2:name)          CFG_NAME=$val ;;
      me:2:role)          CFG_ROLE=$val ;;
      me:2:company)       CFG_COMPANY=$val ;;
      me:2:language)      CFG_LANG=$val ;;
      people:*:name)      P_NAME[$pi]=$val; P_SLUG[$pi]=''; P_REL[$pi]=''; P_ROLE[$pi]='' ;;
      people:*:slug)      P_SLUG[$pi]=$val ;;
      people:*:relation)  P_REL[$pi]=$val ;;
      people:*:role)      P_ROLE[$pi]=$val ;;
      reviews:*:person)   R_PERSON[$ri]=$val; R_FORMAT[$ri]='' ;;
      reviews:*:format)   R_FORMAT[$ri]=$val ;;
    esac
  done <"$CONFIG"
  local i=0
  while [ "$i" -lt "${#P_SLUG[@]}" ]; do
    [ -n "${P_SLUG[$i]}" ] && slug_reserve "${P_SLUG[$i]}"
    i=$((i + 1))
  done
}

# Name for a slug, from the loaded config
name_for_slug() {
  local i=0
  [ "$1" = self ] && { printf '%s' "$CFG_NAME"; return 0; }
  while [ "$i" -lt "${#P_SLUG[@]}" ]; do
    if [ "${P_SLUG[$i]}" = "$1" ]; then printf '%s' "${P_NAME[$i]}"; return 0; fi
    i=$((i + 1))
  done
  printf '%s' "$1"
}

# config_append_items SECTION   (items on stdin, already indented)
# Appends at the end of a top-level list in config.yml. Blank lines and comments
# around the list are kept where they are.
config_append_items() {
  local section=$1 items line rest cur='' held=0 done=0 tmp
  items=$(cat)
  tmp=$(mktemp "${TMPDIR:-/tmp}/rh-setup.XXXXXX")
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$(trim "$line")" ]; then held=$((held + 1)); continue; fi
    case "$line" in
      [A-Za-z_]*:*)
        if [ "$cur" = "$section" ] && [ "$done" -eq 0 ]; then printf '%s\n' "$items"; done=1; fi
        cur=${line%%:*}
        if [ "$cur" = "$section" ]; then
          # "people: []" becomes "people:"; an aligned comment after the [] stays.
          case "$line" in
            *'[]'*)
              rest=${line#*\[\]}
              line=$(trim "${line%%\[\]*}")
              case "$rest" in *'#'*) line=$(aligned "$line" "#${rest#*#}") ;; esac
              ;;
          esac
        fi
        ;;
    esac
    while [ "$held" -gt 0 ]; do printf '\n'; held=$((held - 1)); done
    printf '%s\n' "$line"
  done <"$CONFIG" >"$tmp"
  if [ "$cur" = "$section" ] && [ "$done" -eq 0 ]; then printf '%s\n' "$items" >>"$tmp"; done=1; fi
  while [ "$held" -gt 0 ]; do printf '\n' >>"$tmp"; held=$((held - 1)); done
  if [ "$done" -eq 0 ]; then rm -f "$tmp"; die "could not find '$section:' in $(rel "$CONFIG")"; fi
  mv "$tmp" "$CONFIG"
}

# config_set_cycle CYCLE   (rewrites the cycle: line, keeps its comment)
config_set_cycle() {
  local line comment tmp found=0
  tmp=$(mktemp "${TMPDIR:-/tmp}/rh-setup.XXXXXX")
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      cycle:*)
        comment=''
        case "$line" in *'#'*) comment="#${line#*#}" ;; esac
        if [ -n "$comment" ]; then aligned "cycle: $(yaml_str "$1")" "$comment"; else say "cycle: $(yaml_str "$1")"; fi
        found=1
        ;;
      *) printf '%s\n' "$line" ;;
    esac
  done <"$CONFIG" >"$tmp"
  if [ "$found" -eq 0 ]; then rm -f "$tmp"; die "no 'cycle:' line in $(rel "$CONFIG")"; fi
  mv "$tmp" "$CONFIG"
  printf '  %supdated%s  %s (cycle: %s)\n' "$GREEN" "$RESET" "$(rel "$CONFIG")" "$1"
}

# ---------------------------------------------------------------------------
# Collecting people
# ---------------------------------------------------------------------------

# collect_person NAME RELATION ROLE FORMAT -> appends to NEW_* arrays (validates)
collect_person() {
  local name relation role format slug
  name=$(trim "$1"); relation=$(lower "$(trim "$2")"); role=$(trim "$3"); format=$(trim "$4")
  [ -n "$name" ] || die "a person without a name in RH_PEOPLE"
  valid_relation "$relation" || die "relation for $name must be manager, peer or report (got '$relation')"
  [ -n "$format" ] || format=$(default_format_for "$relation")
  format_file "$format" >/dev/null || die "no format '$format' for $name (available: $(list_formats))"
  make_slug "$name"
  slug=$MADE_SLUG
  NEW_NAME[${#NEW_NAME[@]}]=$name
  NEW_SLUG[${#NEW_SLUG[@]}]=$slug
  NEW_REL[${#NEW_REL[@]}]=$relation
  NEW_ROLE[${#NEW_ROLE[@]}]=$role
  NEW_FORMAT[${#NEW_FORMAT[@]}]=$format
}

# Parse RH_PEOPLE: "Name|relation|role;Name|relation|role[|format]"
collect_people_from_env() {
  local entries entry name relation role format
  [ -n "${RH_PEOPLE-}" ] || return 0
  IFS=';' read -r -a entries <<<"$RH_PEOPLE"
  for entry in "${entries[@]}"; do
    [ -n "$(trim "$entry")" ] || continue
    IFS='|' read -r name relation role format <<<"$entry"
    collect_person "$name" "${relation-}" "${role-}" "${format-}"
  done
}

# Interactive loop until an empty name
collect_people_interactively() {
  local name relation role format n=1
  say ''
  say "Who do you need to review this cycle? Leave the name empty when you are done."
  say "Formats: $(list_formats). The default follows the relation."
  while :; do
    say ''
    ask name "Person $n, name" ''
    [ -n "$name" ] || break
    if person_exists "$name"; then
      printf '  %skept%s     %s is already in config.yml\n' "$DIM" "$RESET" "$name"
      continue
    fi
    while :; do
      ask relation "  relation (manager/peer/report)" peer
      relation=$(lower "$relation")
      valid_relation "$relation" && break
      say "  Use one of: manager, peer, report."
    done
    ask role "  role" ''
    while :; do
      ask format "  format" "$(default_format_for "$relation")"
      format_file "$format" >/dev/null && break
      say "  No such format. Available: $(list_formats)."
    done
    collect_person "$name" "$relation" "$role" "$format"
    say "  slug: ${NEW_SLUG[$((${#NEW_SLUG[@]} - 1))]}"
    n=$((n + 1))
  done
}

# ---------------------------------------------------------------------------
# Flow: fresh workspace
# ---------------------------------------------------------------------------

fresh_setup() {
  heading "New workspace"
  if [ "$YES" = 1 ]; then
    say "Taking answers from the environment (-y)."
  else
    say "A few questions. Press enter to take a default."
    say ''
  fi
  ask_required OWNER_NAME "Your name" "${RH_NAME-}"
  ask OWNER_ROLE "Your role" "${RH_ROLE-}"
  ask OWNER_COMPANY "Your company" "${RH_COMPANY-}"
  ask OWNER_LANG "Language for reviews" "${RH_LANG:-en}"
  OWNER_LANG=$(lower "$OWNER_LANG")
  [ -n "$OWNER_LANG" ] || OWNER_LANG=en
  ask_cycle CYCLE "${RH_CYCLE:-$(default_cycle)}"

  if [ "$YES" = 1 ]; then
    collect_people_from_env
  else
    collect_people_interactively
    say ''
  fi

  if ask_yn "Self review this cycle?" "${RH_SELF:-y}"; then SELF_REVIEW=1; else SELF_REVIEW=0; fi

  heading "Writing files"
  local content i=0
  content=$(render_config)
  write_if_absent "$CONFIG" <<<"$content"
  while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
    write_person "${NEW_NAME[$i]}" "${NEW_SLUG[$i]}" "${NEW_REL[$i]}" "${NEW_ROLE[$i]}"
    i=$((i + 1))
  done
  write_cycle_readme "$CYCLE"
  [ "$SELF_REVIEW" -eq 1 ] && write_progress "$OWNER_NAME" self self "$CYCLE"
  i=0
  while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
    write_progress "${NEW_NAME[$i]}" "${NEW_SLUG[$i]}" "${NEW_FORMAT[$i]}" "$CYCLE"
    i=$((i + 1))
  done
  write_voice_readme

  heading "Summary"
  say "  owner    $OWNER_NAME${OWNER_ROLE:+, $OWNER_ROLE}${OWNER_COMPANY:+ at $OWNER_COMPANY} ($OWNER_LANG)"
  say "  cycle    $CYCLE"
  i=0
  while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
    say "  review   ${NEW_FORMAT[$i]} ${NEW_SLUG[$i]}  (${NEW_NAME[$i]}, ${NEW_REL[$i]})"
    i=$((i + 1))
  done
  [ "$SELF_REVIEW" -eq 1 ] && say "  review   self self  ($OWNER_NAME)"
  say "  files    $CREATED created, $KEPT kept"
}

# ---------------------------------------------------------------------------
# Flow: existing workspace, add a cycle or people
# ---------------------------------------------------------------------------

show_existing() {
  local i=0 people='' reviews=''
  heading "Workspace already configured"
  say "  config   $(rel "$CONFIG")"
  say "  owner    $CFG_NAME${CFG_ROLE:+, $CFG_ROLE}${CFG_COMPANY:+ at $CFG_COMPANY}${CFG_LANG:+ ($CFG_LANG)}"
  say "  cycle    ${CFG_CYCLE:-none}"
  while [ "$i" -lt "${#P_NAME[@]}" ]; do
    people="$people${people:+, }${P_SLUG[$i]} (${P_REL[$i]}${P_ROLE[$i]:+, ${P_ROLE[$i]}})"
    i=$((i + 1))
  done
  say "  people   ${people:-none}"
  i=0
  while [ "$i" -lt "${#R_PERSON[@]}" ]; do
    reviews="$reviews${reviews:+, }${R_FORMAT[$i]} ${R_PERSON[$i]}"
    i=$((i + 1))
  done
  say "  reviews  ${reviews:-none}"
}

# start_cycle CYCLE: sets it current and creates the folders for every review in config
start_cycle() {
  local cycle i=0
  cycle=$(slugify_cycle "$1")
  valid_cycle "$cycle" || die "cycle name '$1' is not usable: $CYCLE_RULE"
  heading "Cycle $cycle"
  if [ "$cycle" != "$CFG_CYCLE" ]; then
    config_set_cycle "$cycle"
    CFG_CYCLE=$cycle
  fi
  write_cycle_readme "$cycle"
  while [ "$i" -lt "${#R_PERSON[@]}" ]; do
    write_progress "$(name_for_slug "${R_PERSON[$i]}")" "${R_PERSON[$i]}" "${R_FORMAT[$i]}" "$cycle"
    i=$((i + 1))
  done
  [ "${#R_PERSON[@]}" -gt 0 ] || warn "config.yml has no reviews: yet, add a person first"
}

# add_people: NEW_* arrays -> config.yml, people files, progress in the current cycle
add_people() {
  local i=0 items=''
  [ "${#NEW_NAME[@]}" -gt 0 ] || return 0
  [ -n "$CFG_CYCLE" ] || warn "config.yml has no cycle: set, progress files are skipped until one exists"
  while [ "$i" -lt "${#NEW_NAME[@]}" ]; do
    items=$(printf '%s' "$(kv '  - ' name "${NEW_NAME[$i]}")")
    items="$items"$'\n'"    slug: ${NEW_SLUG[$i]}"
    items="$items"$'\n'"    relation: ${NEW_REL[$i]}"
    items="$items"$'\n'"$(kv '    ' role "${NEW_ROLE[$i]}")"
    config_append_items people <<<"$items"
    items="  - person: ${NEW_SLUG[$i]}"$'\n'"    format: ${NEW_FORMAT[$i]}"
    config_append_items reviews <<<"$items"
    printf '  %supdated%s  %s (%s)\n' "$GREEN" "$RESET" "$(rel "$CONFIG")" "${NEW_SLUG[$i]}"
    write_person "${NEW_NAME[$i]}" "${NEW_SLUG[$i]}" "${NEW_REL[$i]}" "${NEW_ROLE[$i]}"
    if [ -n "$CFG_CYCLE" ]; then
      write_cycle_readme "$CFG_CYCLE"
      write_progress "${NEW_NAME[$i]}" "${NEW_SLUG[$i]}" "${NEW_FORMAT[$i]}" "$CFG_CYCLE"
    fi
    i=$((i + 1))
  done
}

# True when a person with this exact name is already in config
person_exists() {
  local i=0
  while [ "$i" -lt "${#P_NAME[@]}" ]; do
    [ "${P_NAME[$i]}" = "$1" ] && return 0
    i=$((i + 1))
  done
  return 1
}

extend_setup() {
  load_config
  show_existing

  if [ "$YES" = 1 ]; then
    local did=0
    if [ -n "${RH_CYCLE-}" ] && [ "$(slugify_cycle "$RH_CYCLE")" != "$CFG_CYCLE" ]; then
      start_cycle "$RH_CYCLE"
      did=1
    fi
    if [ -n "${RH_PEOPLE-}" ]; then
      local entries entry name relation role format
      heading "Adding people"
      IFS=';' read -r -a entries <<<"$RH_PEOPLE"
      for entry in "${entries[@]}"; do
        [ -n "$(trim "$entry")" ] || continue
        IFS='|' read -r name relation role format <<<"$entry"
        if person_exists "$(trim "$name")"; then
          printf '  %skept%s     %s is already in config.yml\n' "$DIM" "$RESET" "$(trim "$name")"
          continue
        fi
        collect_person "$name" "${relation-}" "${role-}" "${format-}"
      done
      add_people
      did=1
    fi
    if [ "$did" -eq 0 ]; then
      say ''
      say "Nothing to do. With -y, set RH_CYCLE to start a new cycle or RH_PEOPLE to add people."
      return 0
    fi
  else
    local choice cycle name relation role format
    while :; do
      say ''
      say "What do you want to do?"
      say "  1) start a new cycle"
      say "  2) add a person"
      say "  q) nothing, exit"
      ask choice "Choice" q
      case "$choice" in
        1)
          ask_cycle cycle "$(default_cycle)"
          start_cycle "$cycle"
          ;;
        2)
          NEW_NAME=() NEW_SLUG=() NEW_REL=() NEW_ROLE=() NEW_FORMAT=()
          collect_people_interactively
          [ "${#NEW_NAME[@]}" -gt 0 ] && heading "Adding people"
          add_people
          load_config
          ;;
        *) break ;;
      esac
    done
  fi

  heading "Summary"
  say "  files    $CREATED created, $KEPT kept"
}

# ---------------------------------------------------------------------------
# Privacy check and next steps
# ---------------------------------------------------------------------------

# Say whether origin is the upstream Review Harness repository rather than the
# owner's own copy. With gh logged in the owner's login settles it; without it,
# a remote that names review-harness gets a conditional warning.
check_upstream_remote() {
  local url login='' owner_part
  url=$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null) || url=''
  [ -n "$url" ] || return 0
  case "$(lower "$url")" in *review-harness*) ;; *) return 0 ;; esac
  if command -v gh >/dev/null 2>&1; then
    login=$(gh api user -q .login 2>/dev/null) || login=''
  fi
  if [ -n "$login" ]; then
    # Everything before the last path segment, down to the preceding : or /
    owner_part=${url%/*}
    owner_part=${owner_part##*[/:]}
    [ "$(lower "$owner_part")" = "$(lower "$login")" ] && return 0
    warn "origin points at $url, which is not your own repository."
  else
    warn "origin points at $url. If this remote is not your own repository:"
  fi
  say "  Create a private repository and point origin at it before committing anything:"
  say "    git remote set-url origin <url>"
}

# Uncomment the two workspace/** lines in .gitignore. If they are not there at
# all, add both. Never add a third.
ignore_workspace() {
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/rh-setup.XXXXXX")
  sed -e 's~^# workspace/\*\*$~workspace/**~' -e 's~^# !workspace/README\.md$~!workspace/README.md~' "$ROOT/.gitignore" >"$tmp"
  grep -q -x -F 'workspace/**' "$tmp" || printf 'workspace/**\n' >>"$tmp"
  grep -q -x -F '!workspace/README.md' "$tmp" || printf '!workspace/README.md\n' >>"$tmp"
  mv "$tmp" "$ROOT/.gitignore"
  printf '  %supdated%s  .gitignore\n' "$GREEN" "$RESET"
}

privacy_check() {
  heading "Privacy"
  say "Reviews contain candid judgments about colleagues. Keep the workspace private."
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local vis=''
    if command -v gh >/dev/null 2>&1; then
      vis=$(cd "$ROOT" && gh repo view --json visibility -q .visibility 2>/dev/null) || vis=''
    fi
    case "$(lower "$vis")" in
      public)
        warn "This repository is PUBLIC on GitHub."
        check_upstream_remote
        say "  Make it private, or keep the workspace out of git by uncommenting the two"
        say "  workspace lines in .gitignore."
        if [ "$YES" != 1 ] && [ -f "$ROOT/.gitignore" ] && ask_yn "  Add workspace/ to .gitignore now?" n; then
          ignore_workspace
        fi
        ;;
      private|internal)
        say "  This repository is $(lower "$vis"). Good."
        ;;
      *)
        say "  This is a git repository. Could not confirm its visibility (gh missing or not logged in),"
        say "  so make sure it is private, or uncomment the workspace lines in .gitignore."
        ;;
    esac
  else
    say "  No git repository here, so the files live only on this machine."
    say "  A private repository is a reasonable way to keep history."
  fi
}

next_steps() {
  heading "Next"
  say "  1. Check $(rel "$CONFIG") and fill in handles if you want evidence gathering."
  say "  2. Drop past reviews and other writing into $(rel "$WORKSPACE/voice/samples"), then run the voice workflow (review-voice)."
  say "  3. Run the evidence workflow (review-evidence <slug>) before the first interview, then start with review <format> <slug>."
  say ''
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -y|--yes) YES=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1 (try -h)" ;;
    esac
    shift
  done

  printf '%sReview Harness setup%s\n' "$BOLD" "$RESET"
  say "workspace: $(rel "$WORKSPACE")/"

  mkdir -p "$WORKSPACE"
  if [ -f "$CONFIG" ]; then
    extend_setup
  else
    fresh_setup
  fi
  privacy_check
  next_steps
}

main "$@"
