# Source: GitHub

The most reliable source. Merged PRs, reviews given, commit activity, plus PR sizes if a code-quality goal is in play.

## Detect

```sh
gh auth status && gh api user --jq .login
```

If that fails, look for a GitHub MCP connector. If neither, skip and note it.

## Find the org and window

Orgs come from `config.yml` `evidence.github_orgs`. If empty:

```sh
gh api user/orgs --jq '.[].login'
```

Set `SINCE` to the start of the window in `YYYY-MM-DD`.

## Volume and substance

Merged PRs authored by the subject, one line each, sorted by date:

```sh
gh search prs --author=<login> --owner=<org> --merged --merged-at=">=$SINCE" \
  --limit 300 --json number,title,repository,closedAt,url \
  --jq '.[] | "\(.closedAt[:10]) \(.repository.name)#\(.number) \(.title) \(.url)"' | sort
```

Open PRs, to see what is in flight:

```sh
gh search prs --author=<login> --owner=<org> --state=open --limit 50 \
  --json number,title,repository,createdAt,url \
  --jq '.[] | "\(.createdAt[:10]) \(.repository.name)#\(.number) \(.title) \(.url)"'
```

PRs the subject reviewed for others, and for whom:

```sh
gh search prs --reviewed-by=<login> --owner=<org> --updated=">=$SINCE" --limit 300 \
  --json author --jq '[.[] | select(.author.login != "<login>") | .author.login]
  | group_by(.) | map({a: .[0], n: length}) | sort_by(-.n) | .[] | "\(.n) \(.a)"'
```

Repositories touched, from the merged list: count by repository name. A new repo appearing is usually a story (a hackathon project, a new service).

## PR sizes, when a "small PRs" goal exists

```sh
gh search prs --author=<login> --repo=<org>/<repo> --merged --merged-at=">=$SINCE" \
  --limit 300 --json number --jq '.[].number' | while read n; do
  gh api repos/<org>/<repo>/pulls/$n --jq '[.additions, .deletions] | add'
done | sort -n | awk '{a[NR]=$1} END {print "count", NR, "median", a[int(NR/2)+1]}'
```

Report the count under 400 lines, between 400 and 1000, and over 1000, plus the median. Name the five largest so the owner can explain them.

## Moments

Look in the merged list for: hotfixes late on a Friday, "revert", "incident", "remove ... entirely", first commits to a new repo, anything touching CI or developer tooling, anything named after a partner or a launch. Confirm dates with the PR page if the title is ambiguous:

```sh
gh pr view <url> --json title,body,mergedAt,reviews --jq '{title, mergedAt, body: .body[:600]}'
```

## What to write down

For each PR line keep the date, repo, number, title and URL. Group by theme later. Do not paste diffs into the evidence file.

A ready-made dump script lives in `scripts/evidence-github.sh`.
