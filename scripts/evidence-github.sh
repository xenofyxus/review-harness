#!/usr/bin/env bash
# evidence-github.sh: dump GitHub evidence for one person as markdown.
#
# Mirrors the recipes in harness/sources/github.md: merged PRs, open PRs,
# reviews given for others and, with -z, PR size stats for one repo.
# Markdown goes to stdout, progress goes to stderr. Reads only, never writes.
# Needs the gh CLI, authenticated. Runs on macOS bash 3.2 and on Linux.
#
# Usage: scripts/evidence-github.sh -u <login> -o <org> [-o <org2>] -s <YYYY-MM-DD> [-l <limit>] [-z <org/repo>]

set -eu
set -o pipefail

usage() {
  cat <<'USAGE'
Usage: evidence-github.sh -u <login> -o <org> [-o <org2> ...] -s <YYYY-MM-DD> [-l <limit>] [-z <org/repo>]

Dumps GitHub evidence for one person as markdown on stdout. Progress goes to stderr.
Nothing is written to stdout until every search has succeeded, so redirecting to a file is safe.

  -u <login>     GitHub login of the subject (required)
  -o <org>       GitHub org to search, repeat the flag for several (required)
  -s <date>      start of the window as YYYY-MM-DD (required)
  -l <limit>     max results per search, 1 to 1000 (default 300; open PRs are capped at 50)
  -z <org/repo>  also report PR sizes for this repo (one API call per merged PR)
  -h             show this help

Examples:
  scripts/evidence-github.sh -u mayalq -o northwind-labs -s 2026-03-15
  scripts/evidence-github.sh -u mayalq -o northwind-labs -o northwind-oss -s 2026-03-15 -z northwind-labs/api \
    > workspace/cycles/2026-h2/self/evidence-raw.md
USAGE
}

log() { printf '%s\n' "$*" >&2; }
die() { log "evidence-github.sh: $*"; exit 1; }
count_lines() { awk 'END { print NR }' "$1"; }

# ---------- options ----------

login=""
since=""
limit=300
size_repo=""
orgs=()

while getopts "u:o:s:l:z:h" opt; do
  case "$opt" in
    u) login=$OPTARG ;;
    o) orgs+=("$OPTARG") ;;
    s) since=$OPTARG ;;
    l) limit=$OPTARG ;;
    z) size_repo=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[ -n "$login" ] || { usage >&2; die "-u <login> is required"; }
[ "${#orgs[@]}" -gt 0 ] || { usage >&2; die "at least one -o <org> is required"; }
[ -n "$since" ] || { usage >&2; die "-s <YYYY-MM-DD> is required"; }

case "$since" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) die "-s expects a date as YYYY-MM-DD, got '$since'" ;;
esac

case "$limit" in
  ''|*[!0-9]*) die "-l expects a number, got '$limit'" ;;
esac
[ "$limit" -ge 1 ] && [ "$limit" -le 1000 ] || die "-l must be between 1 and 1000 (gh search stops at 1000)"

if [ -n "$size_repo" ]; then
  case "$size_repo" in
    */*) ;;
    *) die "-z expects org/repo, got '$size_repo'" ;;
  esac
fi

# ---------- preflight ----------

command -v gh >/dev/null 2>&1 || die "the gh CLI is not installed. See https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"

owner_args=()
for org in "${orgs[@]}"; do
  owner_args+=("--owner=$org")
done
orgs_label=$(printf '%s, ' "${orgs[@]}")
orgs_label=${orgs_label%, }
login_lc=$(printf '%s' "$login" | tr '[:upper:]' '[:lower:]')
today=$(date +%Y-%m-%d)
tab=$(printf '\t')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# ---------- fetch ----------
# Every search lands in a temp file first. Stdout stays empty until all of them succeed.

log "GitHub evidence for $login in $orgs_label, $since to $today"

log "Searching merged PRs (limit $limit)"
gh search prs --author="$login" "${owner_args[@]}" --merged --merged-at=">=$since" \
  --limit "$limit" --json number,title,repository,closedAt,url \
  --jq '.[] | "\(.closedAt[:10]) \(.repository.name)#\(.number) \(.title) \(.url)"' \
  | LC_ALL=C sort > "$tmp/merged" \
  || die "search for merged PRs failed, see the message above"
merged_n=$(count_lines "$tmp/merged")
log "  $merged_n merged"
[ "$merged_n" -lt "$limit" ] || log "  warning: hit the limit of $limit, raise -l to see everything"

log "Searching open PRs (limit 50)"
gh search prs --author="$login" "${owner_args[@]}" --state=open --limit 50 \
  --json number,title,repository,createdAt,url \
  --jq '.[] | "\(.createdAt[:10]) \(.repository.name)#\(.number) \(.title) \(.url)"' \
  | LC_ALL=C sort > "$tmp/open" \
  || die "search for open PRs failed, see the message above"
open_n=$(count_lines "$tmp/open")
log "  $open_n open"

log "Searching PRs reviewed for others (limit $limit)"
# The first output line carries the raw result count, so the limit warning can
# see it; the grouped lines after it leave out the subject's own PRs.
gh search prs --reviewed-by="$login" "${owner_args[@]}" --updated=">=$since" --limit "$limit" \
  --json author \
  --jq '"found \(length)", ([.[] | select((.author.login | ascii_downcase) != "'"$login_lc"'") | .author.login]
        | group_by(.) | map({a: .[0], n: length}) | sort_by(-.n) | .[] | "\(.n) \(.a)")' \
  > "$tmp/reviews-raw" \
  || die "search for reviewed PRs failed, see the message above"
found_n=$(awk 'NR == 1 && $1 == "found" { print $2 + 0 }' "$tmp/reviews-raw")
[ -n "$found_n" ] || die "search for reviewed PRs returned no count line, see the message above"
awk 'NR > 1' "$tmp/reviews-raw" > "$tmp/reviews"
reviews_n=$(awk '{ s += $1 } END { print s + 0 }' "$tmp/reviews")
authors_n=$(count_lines "$tmp/reviews")
log "  $reviews_n PRs reviewed for $authors_n people"
[ "$found_n" -lt "$limit" ] || log "  warning: hit the limit of $limit, raise -l to see everything"

sized_n=0
if [ -n "$size_repo" ]; then
  log "Searching merged PRs in $size_repo for size stats (limit $limit)"
  gh search prs --author="$login" --repo="$size_repo" --merged --merged-at=">=$since" \
    --limit "$limit" --json number,title,url \
    --jq '.[] | "\(.number)\t\(.title)\t\(.url)"' \
    > "$tmp/size-prs" \
    || die "search for PRs in $size_repo failed, see the message above"
  size_total=$(count_lines "$tmp/size-prs")
  [ "$size_total" -lt "$limit" ] || log "  warning: hit the limit of $limit, raise -l to see everything"

  # One API call per PR. Size is additions plus deletions, as in the recipe.
  : > "$tmp/sizes"
  i=0
  while IFS="$tab" read -r n title url; do
    i=$((i + 1))
    log "  size $i/$size_total: #$n"
    size=$(gh api "repos/$size_repo/pulls/$n" --jq '[.additions, .deletions] | add') \
      || { log "  could not fetch #$n, skipping it"; continue; }
    printf '%s\t%s\t%s\t%s\n' "$size" "$n" "$title" "$url" >> "$tmp/sizes"
  done < "$tmp/size-prs"
  sized_n=$(count_lines "$tmp/sizes")
  log "  $sized_n PRs sized"
fi

# ---------- render ----------

cat <<HEADER
# GitHub evidence for $login

| | |
|---|---|
| Login | $login |
| Orgs | $orgs_label |
| Window | $since to $today |
| Generated | $today by scripts/evidence-github.sh |

Everything below is what GitHub shows. What it means is for the interview.

## Merged pull requests

HEADER

if [ "$merged_n" -eq 0 ]; then
  echo "No merged pull requests in this window."
else
  sed 's/^/- /' "$tmp/merged"
  echo
  echo "Merged in the window: $merged_n"
  echo
  echo "| Repo | Merged |"
  echo "|---|---|"
  awk '{ print $2 }' "$tmp/merged" | sed 's/#.*//' \
    | LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn \
    | awk '{ print "| " $2 " | " $1 " |" }'
fi
echo

echo "## Open pull requests"
echo
if [ "$open_n" -eq 0 ]; then
  echo "No open pull requests."
else
  sed 's/^/- /' "$tmp/open"
  echo
  echo "Open right now: $open_n"
fi
echo

echo "## Reviews given"
echo
if [ "$reviews_n" -eq 0 ]; then
  echo "No reviews on other people's pull requests in this window."
else
  echo "PRs reviewed for others: $reviews_n, across $authors_n people. Counts PRs updated in the window that $login reviewed, own PRs excluded."
  echo
  echo "| Author | PRs reviewed |"
  echo "|---|---|"
  awk '{ print "| " $2 " | " $1 " |" }' "$tmp/reviews"
fi
echo

if [ -n "$size_repo" ]; then
  repo_short=${size_repo#*/}
  echo "## PR sizes"
  echo
  if [ "$sized_n" -eq 0 ]; then
    echo "No merged pull requests by $login in $size_repo in this window."
  else
    LC_ALL=C sort -t "$tab" -k1,1n "$tmp/sizes" > "$tmp/sizes-sorted"
    # Median follows the recipe: the upper middle value for even counts.
    read -r small mid large median <<STATS
$(awk -F "$tab" '
      { a[NR] = $1; if ($1 < 400) s++; else if ($1 < 1000) m++; else l++ }
      END { print s + 0, m + 0, l + 0, a[int(NR / 2) + 1] }' "$tmp/sizes-sorted")
STATS
    echo "Merged PRs by $login in $size_repo, size measured as lines added plus lines deleted."
    echo
    echo "| | |"
    echo "|---|---|"
    echo "| Total | $sized_n |"
    echo "| Under 400 lines | $small |"
    echo "| 400 to 999 lines | $mid |"
    echo "| 1000 lines and over | $large |"
    echo "| Median | $median |"
    echo
    if [ "$sized_n" -gt 5 ]; then echo "Five largest:"; else echo "All $sized_n, largest first:"; fi
    echo
    LC_ALL=C sort -t "$tab" -k1,1nr "$tmp/sizes" \
      | awk -F "$tab" -v repo="$repo_short" 'NR <= 5 { print "- " $1 " lines " repo "#" $2 " " $3 " " $4 }'
  fi
  echo
fi

log "Done."
