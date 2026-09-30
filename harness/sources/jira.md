# Source: Jira

Issues the subject resolved, issues they reported, epics they carried. Same ground as Linear, different query language. This guide is for Jira Cloud.

## Detect

Prefer an Atlassian MCP connector if the harness has one (the Rovo server exposes tools named `searchJiraIssuesUsingJql`, `getJiraIssue`, `lookupJiraAccountId`). Otherwise the Jira Cloud REST API v3 with basic auth from three variables: `JIRA_BASE_URL` (`https://<site>.atlassian.net`), `JIRA_EMAIL` and `JIRA_API_TOKEN` (an API token from `https://id.atlassian.com/manage/api-tokens`, not a password):

```sh
test -n "$JIRA_BASE_URL" && test -n "$JIRA_EMAIL" && test -n "$JIRA_API_TOKEN" && \
  curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_BASE_URL/rest/api/3/myself" | grep -o '"displayName":"[^"]*"'
```

If neither, skip and note it.

## Which search endpoint

`/rest/api/3/search` was deprecated in October 2024 and switched off during 2025. Use `/rest/api/3/search/jql`, GET or POST. Four things changed and all four matter here:

- It returns issue ids only unless you pass `fields`.
- It pages with `nextPageToken`, not `startAt`. No jumping to page N.
- The response has no `total`. Counts come from `POST /rest/api/3/search/approximate-count`.
- Unbounded JQL (no clause that narrows the set) is rejected with 400. Every query below has a date bound.

`maxResults` defaults to 50 and goes up to 5000. The examples use 100.

## Find the subject's account id

JQL user fields take an account id. Resolve it once from the email or display name in `people/<slug>.md` and save it back under `handles: jira:` (or `me.handles.jira` for self) so this is not repeated.

MCP: `lookupJiraAccountId` with the name or email.

REST:

```sh
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -G "$JIRA_BASE_URL/rest/api/3/user/search" \
  --data-urlencode 'query=<email or display name>' | grep -o '"accountId":"[^"]*"\|"displayName":"[^"]*"'
```

An exact email works even when the user has hidden their email; the address is just not echoed back.

## Queries

Set `SINCE` to the start of the window in `YYYY-MM-DD` and `ACCOUNT` to the account id. Fields to keep on every query: `summary,status,resolutiondate,issuetype,parent,priority`. The key comes back at the top level of each issue, so it is never requested.

**Resolved in the window**, assignee = subject, newest first:

```
assignee = <ACCOUNT> AND resolved >= "<SINCE>" ORDER BY resolved DESC
```

**Reported by the subject**, created in the window. Reported and fixed by someone else is a sign of spotting problems, so keep these apart from the resolved list:

```
reporter = <ACCOUNT> AND created >= "<SINCE>" ORDER BY created DESC
```

**Epics they carried.** Jira has no lead field on an epic, so assignee is the usual proxy. Updated in the window catches epics still open:

```
issuetype = Epic AND assignee = <ACCOUNT> AND updated >= "<SINCE>" ORDER BY resolved DESC
```

Then, for each epic that looks important, its children, to count done against open:

```
parent = <EPIC-KEY> ORDER BY resolved DESC
```

`parent` replaced `"Epic Link"` in 2024. Old saved filters using `"Epic Link"` still run, but write `parent`.

MCP: `searchJiraIssuesUsingJql` with the JQL string, the fields list and `maxResults`, then the `nextPageToken` it hands back.

REST, POST form. It takes long JQL without URL encoding, so prefer it:

```sh
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X POST "$JIRA_BASE_URL/rest/api/3/search/jql" \
  -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -d '{"jql": "assignee = <ACCOUNT> AND resolved >= \"<SINCE>\" ORDER BY resolved DESC",
       "fields": ["summary", "status", "resolutiondate", "issuetype", "parent", "priority"],
       "maxResults": 100}'
```

GET form, for a short query typed by hand. `fields` is comma separated here:

```sh
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -G "$JIRA_BASE_URL/rest/api/3/search/jql" \
  --data-urlencode 'jql=reporter = <ACCOUNT> AND created >= "<SINCE>" ORDER BY created DESC' \
  --data-urlencode 'fields=summary,status,resolutiondate,issuetype,parent,priority' \
  --data-urlencode 'maxResults=100'
```

## Paging

The response carries `issues`, `isLast` and, when there is more, `nextPageToken`. Send the token back unchanged in the next request. Stop when `isLast` is true or the token is missing. This loop prints one line per issue and needs `jq`:

```sh
JQL='assignee = <ACCOUNT> AND resolved >= "<SINCE>" ORDER BY resolved DESC'
TOKEN=""
while :; do
  BODY=$(jq -n --arg jql "$JQL" --arg t "$TOKEN" \
    '{jql: $jql, maxResults: 100, fields: ["summary","status","resolutiondate","issuetype","parent","priority"]}
     + (if $t != "" then {nextPageToken: $t} else {} end)')
  PAGE=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X POST "$JIRA_BASE_URL/rest/api/3/search/jql" \
    -H 'Content-Type: application/json' -d "$BODY")
  echo "$PAGE" | jq -r '.issues[] | "\(.fields.resolutiondate[:10] // "open") \(.key) [\(.fields.issuetype.name)] \(.fields.summary) (\(.fields.status.name), parent \(.fields.parent.key // "-"))"'
  TOKEN=$(echo "$PAGE" | jq -r '.nextPageToken // empty')
  [ -z "$TOKEN" ] && break
done
```

Counts for the volume table, one call per JQL string:

```sh
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X POST "$JIRA_BASE_URL/rest/api/3/search/approximate-count" \
  -H 'Content-Type: application/json' -d '{"jql": "assignee = <ACCOUNT> AND resolved >= \"<SINCE>\""}'
```

The count is approximate and can lag a recent change by a little. Fine for volume, not for a claim like "exactly 41".

## What to write down

Key, summary, status, resolution date, issue type, parent key, priority and the URL `$JIRA_BASE_URL/browse/<KEY>`. Group by epic, then by project key (the part of the key before the dash). Count resolved per epic. Note Highest and High priority items separately; they are usually moments.

## Watch for

- A project used as a queue (support, ops, bugs, security): evidence of reliability and support work, not of features. Say which it is.
- Epics with the subject as assignee: ask about them first in the interview.
- Resolved is not done. Check `status` and drop Won't Do, Duplicate and Cannot Reproduce from the counts, or list them apart.
- Two people with the same display name. Match on account id, never on the name in the summary line.
- The MCP search has been reported to return a full page with no `nextPageToken`. If a result stops at exactly the page size, narrow the window to one month at a time and run again.
- Jira Data Center (self-hosted) still uses `/rest/api/2/search` with `startAt` paging and a `total` field. UNVERIFIED for current Data Center releases; check the instance's own REST docs before reusing the loop above.
