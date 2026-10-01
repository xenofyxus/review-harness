# Source: GitLab

Same ground as `github.md`: merged MRs, approvals given, MR sizes when a code-quality goal is in play. The shell examples need `jq`. Only tried when `gitlab` is in `evidence.sources` in `<workspace>/config.yml`.

## Detect

```sh
glab auth status && glab api user | jq -r .username
```

Self-hosted: pass `--hostname <host>` to `glab auth status` and to every `glab api` call below. Without `glab`, use the REST API with a personal access token (`read_api` scope) in `GITLAB_TOKEN` and the instance in `GITLAB_HOST`:

```sh
test -n "$GITLAB_TOKEN" && curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST:-https://gitlab.com}/api/v4/user" | jq -r .username
```

If neither works, skip and note it. The `curl` twin of any `glab api` call below is the same path under `${GITLAB_HOST:-https://gitlab.com}/api/v4/` with that header.

## Find the group and window

Groups come from `evidence.gitlab_groups` in `<workspace>/config.yml`. If the list is empty, show the owner what they can see; a group query covers its subgroups, so the top-level group is usually enough:

```sh
glab api --paginate "groups?min_access_level=10&per_page=100" | jq -r '.[].full_path'
```

Set `SINCE` to the start of the window as `YYYY-MM-DD`. REST date filters want ISO 8601, so the examples append `T00:00:00Z`.

## Volume and substance

Merged MRs authored by the subject, one line each. `glab mr list` has no merged-after flag, so filter on `merged_at` and raise `--page` until an empty list comes back:

```sh
glab mr list --group <group> --author <username> --merged --order merged_at --sort desc \
  --per-page 100 --page 1 --output json \
  | jq -r --arg since "$SINCE" '.[] | select(.merged_at >= $since)
    | "\(.merged_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

`references.full` looks like `northwind-labs/billing!42`: project and MR number in one token. Keep it, since two projects can share a name across groups. The same list without `--merged` shows what is in flight.

Through the API, `glab api --paginate` walks the pages. `-X GET` matters: `glab api` switches to POST as soon as it sees a field, and this workflow never writes. `scope=all` matters: without it the global endpoint returns the caller's own MRs and no error:

```sh
glab api -X GET --paginate "merge_requests?scope=all&state=merged&author_username=<username>&updated_after=${SINCE}T00:00:00Z&order_by=merged_at&sort=desc&per_page=100" \
  | jq -r '.[] | "\(.merged_at[:10]) \(.references.full) \(.title) \(.web_url)"'
```

## Approvals given

`--reviewer <username>` on `glab mr list` only means assigned as reviewer. Approving says they read it, so count approvals. `approved_by_usernames[]` matches MRs approved by every name given, so pass one:

```sh
glab api -X GET --paginate "merge_requests?scope=all&state=merged&approved_by_usernames[]=<username>&updated_after=${SINCE}T00:00:00Z&per_page=100" \
  | jq -r '.[] | select(.author.username != "<username>") | .author.username' | sort | uniq -c | sort -rn
```

Drop bot authors (`author.bot`) before counting.

## MR sizes, when a "small MRs" goal exists

List endpoints carry no line counts and `changes_count` is a string capped at `"1000+"`, so use GraphQL, one query per project. The list goes next to `evidence-raw.md`:

```sh
OUT="<workspace>/cycles/<cycle>/<slug>"
Q="{ project(fullPath: \"<group>/<project>\") {
  mergeRequests(authorUsername: \"<username>\", state: merged, mergedAfter: \"${SINCE}T00:00:00Z\", first: 100) {
    pageInfo { hasNextPage endCursor }
    nodes { iid title diffStatsSummary { additions deletions } } } } }"
glab api graphql -f query="$Q" \
  | jq -r '.data.project.mergeRequests.nodes[] | select(.diffStatsSummary != null)
    | "\(.diffStatsSummary.additions + .diffStatsSummary.deletions) !\(.iid) \(.title)"' \
  | sort -n > "$OUT/mr-sizes.txt"
awk '{a[NR]=$1} END {print "count", NR, "median", a[int(NR/2)+1]}' "$OUT/mr-sizes.txt"
```

If `hasNextPage` is true, add `after: "<endCursor>"` next to `first: 100` and run again. Report the buckets and the five largest as `github.md` says. When done, fold the list into `evidence-raw.md` and delete `mr-sizes.txt`; only `evidence-raw.md` is gitignored. Without `glab`, POST `{"query": ...}` to `${GITLAB_HOST:-https://gitlab.com}/api/graphql` with the same header.

## Moments

Read the merged list the way `github.md` says: hotfixes, reverts, incidents, removals, first MRs into a new project, CI and tooling, partner or launch names. `glab mr view <iid> -R <group>/<project>` confirms an ambiguous title.

## What to write down

For each MR keep the date merged, `references.full`, title and URL; otherwise as `github.md` says.

## Watch for

- `updated_after` over-fetches a little; recent versions accept the exact `merged_after`. Self-hosted instances lag gitlab.com by months, so if `merged_after` or `diffStatsSummary` is rejected, fall back to `updated_after` and `changes_count` and say so under `## Not found`.
- Stay with projects the owner can see anyway. Nothing here should require asking for access to read the subject's work.
