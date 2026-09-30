# Source: GitLab

Same ground as GitHub: merged MRs, reviews and approvals given, MR sizes when a code-quality goal is in play. The `glab` CLI covers most of it. REST and GraphQL fill the gaps, and every `glab` example below has a plain `curl` twin.

## Detect

```sh
glab auth status && glab api user | jq -r .username
```

For a self-hosted instance, `glab auth status --hostname <host>` and pass `--hostname <host>` to the `glab api` calls below. `glab` also reads `GITLAB_TOKEN` and `GITLAB_HOST` from the environment (UNVERIFIED in this session; `glab help environment` lists what the installed version honours).

If `glab` is missing, fall back to the REST API with a personal access token (`read_api` scope) in `GITLAB_TOKEN` and the instance in `GITLAB_HOST`, defaulting to `https://gitlab.com`:

```sh
test -n "$GITLAB_TOKEN" && curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST:-https://gitlab.com}/api/v4/user" | jq -r .username
```

If neither, skip and note it. The shell examples need `jq`.

## Find the group and window

Groups come from `config.yml` `evidence.gitlab_groups`. Add that key next to `github_orgs` if the workspace does not have it yet. If it is empty, list what the owner can see:

```sh
glab api --paginate "groups?min_access_level=10&per_page=100" | jq -r '.[].full_path'
```

A group query covers its subgroups, so the top-level group is usually enough.

Set `SINCE` to the start of the window in `YYYY-MM-DD`. REST date filters want ISO 8601, so the examples append `T00:00:00Z`.

## Volume and substance

Merged MRs authored by the subject, across a group, one line each. `glab mr list` has no merged-after flag, so filter on `merged_at` after the fact and keep raising `--page` until an empty list comes back:

```sh
glab mr list --group <group> --author <username> --merged --order merged_at --sort desc \
  --per-page 100 --page 1 --output json \
  | jq -r --arg since "$SINCE" '.[] | select(.merged_at >= $since)
    | "\(.merged_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

`references.full` looks like `northwind-labs/billing!42`, which is project and MR number in one token.

REST twin, through the global endpoint. It defaults to `scope=created_by_me`, which silently returns the owner's MRs instead of the subject's, so `scope=all` is not optional:

```sh
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -G "${GITLAB_HOST:-https://gitlab.com}/api/v4/merge_requests" \
  --data-urlencode scope=all --data-urlencode state=merged \
  --data-urlencode "author_username=<username>" \
  --data-urlencode "updated_after=${SINCE}T00:00:00Z" \
  --data-urlencode order_by=merged_at --data-urlencode sort=desc \
  --data-urlencode per_page=100 --data-urlencode page=1 \
  | jq -r '.[] | "\(.merged_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

`updated_after` over-fetches a little (an old MR touched recently). Recent GitLab versions also accept `merged_after=${SINCE}T00:00:00Z`, which is exact; use it if the instance does not reject it. The page size caps at 100; the `x-next-page` header is empty on the last page. `glab api --paginate` walks the pages for you:

```sh
glab api -X GET --paginate "merge_requests?scope=all&state=merged&author_username=<username>&updated_after=${SINCE}T00:00:00Z&order_by=merged_at&sort=desc&per_page=100" \
  | jq -r '.[] | "\(.merged_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

The `-X GET` matters: `glab api` switches to POST as soon as it sees a field, and this workflow never writes.

Open MRs, to see what is in flight:

```sh
glab mr list --group <group> --author <username> --per-page 50 --output json \
  | jq -r '.[] | "\(.created_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

## Reviews and approvals given

Two signals, in rising order of strength. Being assigned as reviewer says someone asked. Approving says they read it.

MRs where the subject was a reviewer, and for whom:

```sh
glab mr list --group <group> --reviewer <username> --all --per-page 100 --page 1 --output json \
  | jq -r --arg since "$SINCE" --arg me "<username>" \
    '.[] | select(.updated_at >= $since and .author.username != $me) | .author.username' \
  | sort | uniq -c | sort -rn
```

MRs the subject approved. `approved_by_usernames[]` takes up to five names and matches MRs approved by all of them, so pass one:

```sh
glab api -X GET --paginate "merge_requests?scope=all&state=merged&approved_by_usernames[]=<username>&updated_after=${SINCE}T00:00:00Z&per_page=100" \
  | jq -r '.[] | select(.author.username != "<username>") | .author.username' | sort | uniq -c | sort -rn
```

REST twin: same query string on `${GITLAB_HOST:-https://gitlab.com}/api/v4/merge_requests` with the `PRIVATE-TOKEN` header. `reviewer_username=<username>` is the REST form of `--reviewer`.

Who approved one particular MR, when a story needs confirming. The project path is URL encoded, so the slash becomes `%2F`:

```sh
glab api "projects/<group>%2F<project>/merge_requests/<iid>/approvals" \
  | jq -r '.approved_by[] | "\(.user.username) \(.approved_at[:10])"'
```

Projects touched: count the part of `references.full` before the `!`. A new project appearing is usually a story.

## MR sizes, when a "small MRs" goal exists

Neither list endpoint carries line counts, and the single-MR REST call only has `changes_count`, a string capped at `"1000+"` that counts changes rather than lines. GraphQL has the real numbers. One query per project, merged MRs by the subject since the window start, with additions and deletions:

```sh
Q="{ project(fullPath: \"<group>/<project>\") {
  mergeRequests(authorUsername: \"<username>\", state: merged, mergedAfter: \"${SINCE}T00:00:00Z\", first: 100) {
    pageInfo { hasNextPage endCursor }
    nodes { iid title diffStatsSummary { additions deletions fileCount } } } } }"
glab api graphql -f query="$Q" \
  | jq -r '.data.project.mergeRequests.nodes[] | select(.diffStatsSummary != null)
    | "\(.diffStatsSummary.additions + .diffStatsSummary.deletions) !\(.iid) \(.title)"' \
  | sort -n > mr-sizes.txt
awk '{n[NR]=$1; if ($1 < 400) s++; else if ($1 <= 1000) m++; else l++}
  END {print "count", NR, "median", n[int(NR/2)+1], "under400", s+0, "400to1000", m+0, "over1000", l+0}' mr-sizes.txt
tail -5 mr-sizes.txt
```

If `hasNextPage` is true, add `after: "<endCursor>"` next to `first: 100` and run again. Report the count under 400 lines, between 400 and 1000, and over 1000, plus the median. Name the five largest so the owner can explain them. Delete `mr-sizes.txt` when done, or fold it into `evidence-raw.md`.

REST twin for the GraphQL call: `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -H 'Content-Type: application/json' -X POST "${GITLAB_HOST:-https://gitlab.com}/api/graphql" -d "{\"query\": $(jq -Rs . <<<"$Q")}"`.

## Moments

Look in the merged list for: hotfixes late on a Friday, "revert", "incident", "remove ... entirely", first MRs into a new project, anything touching `.gitlab-ci.yml` or developer tooling, anything named after a partner or a launch. Confirm dates and context with the MR itself if the title is ambiguous:

```sh
glab api "projects/<group>%2F<project>/merge_requests/<iid>" \
  | jq '{title, merged_at, changes_count, description: .description[:600]}'
```

## What to write down

For each MR line keep the date merged, project, `!iid`, title and URL. Group by theme later. Do not paste diffs into the evidence file.

## Watch for

- Bot authors (dependency updaters, release bots) appear in reviewer and approval lists. The MR object has `author.bot`; drop those before counting for whom the subject reviewed.
- `--reviewer` and `reviewer_username` mean assigned as reviewer, not that a review happened. When the number matters, use approvals.
- The global `/merge_requests` endpoint without `scope=all` returns the caller's own MRs and no error. If the subject's list looks like the owner's, that is why.
- Two projects can share a name across groups. Keep `references.full`, not the bare project name.
- Self-hosted instances lag gitlab.com by months. If `merged_after` or `diffStatsSummary` is rejected, fall back to `updated_after` and `changes_count` and say so under `## Not found`.
- Stay with projects the owner can see anyway. Nothing here should require asking for access to read the subject's work.
