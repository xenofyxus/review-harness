# Source: Jira

Issues the subject resolved, issues they reported, epics they carried. Same ground as `linear.md`, different query language. Written for Jira Cloud. Only tried when `jira` is in `evidence.sources` in `<workspace>/config.yml`.

## Detect

Prefer a Jira MCP connector if the harness has one; Atlassian's Rovo server exposes `searchJiraIssuesUsingJql`, `getJiraIssue` and `lookupJiraAccountId`. Otherwise the Jira Cloud REST API v3 with basic auth from `JIRA_BASE_URL` (`https://<site>.atlassian.net`), `JIRA_EMAIL` and `JIRA_API_TOKEN` (an API token, not a password):

```sh
test -n "$JIRA_BASE_URL" && test -n "$JIRA_EMAIL" && test -n "$JIRA_API_TOKEN" && \
  curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_BASE_URL/rest/api/3/myself" | grep -o '"displayName":"[^"]*"'
```

If neither, skip and note it. The paging loop below needs `jq`.

## The search endpoint

`/rest/api/3/search` was switched off during 2025; use `/rest/api/3/search/jql`. It returns ids only unless you pass `fields`, pages with `nextPageToken`, has no `total`, and rejects JQL with no narrowing clause, so every query below has a date bound. `maxResults` defaults to 50; the examples use 100.

## Find the subject's account id

JQL user fields take an account id. Resolve it once from the email or display name on the **Handles:** line of `<workspace>/people/<slug>.md` and write it back to that line as `jira: <account id>`. For `self`, read and write `me.handles.jira` in `<workspace>/config.yml` instead.

MCP: `lookupJiraAccountId` with the name or email. REST: `GET $JIRA_BASE_URL/rest/api/3/user/search?query=<email or name>` returns `accountId` and `displayName`.

## Queries

Set `SINCE` to the start of the window as `YYYY-MM-DD` and `ACCOUNT` to the account id. Fields on every query: `summary,status,resolutiondate,issuetype,parent,priority`. The key comes back at the top level of each issue.

**Resolved in the window**, assignee = subject:

```
assignee = <ACCOUNT> AND resolved >= "<SINCE>" ORDER BY resolved DESC
```

**Reported by the subject.** Reported and fixed by someone else is a sign of spotting problems, so keep these apart:

```
reporter = <ACCOUNT> AND created >= "<SINCE>" ORDER BY created DESC
```

**Epics they carried.** Jira has no lead field on an epic, so assignee is the usual proxy. Updated in the window catches epics still open:

```
issuetype = Epic AND assignee = <ACCOUNT> AND updated >= "<SINCE>" ORDER BY resolved DESC
```

For each epic that looks important, its children, to count done against open. `parent` replaced `"Epic Link"` in 2024:

```
parent = <EPIC-KEY> ORDER BY resolved DESC
```

MCP: `searchJiraIssuesUsingJql` with the JQL, the fields list and `maxResults`, then the `nextPageToken` it hands back.

REST, POST form. Send `nextPageToken` back unchanged until the response has none. One line per issue:

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

Counts for the volume table: POST `{"jql": "..."}` with the same JQL, minus `ORDER BY`, to `$JIRA_BASE_URL/rest/api/3/search/approximate-count`. The count is approximate; fine for volume, not for a claim like "exactly 41".

## What to write down

Key, summary, status, resolution date, issue type, parent key, priority and the URL `$JIRA_BASE_URL/browse/<KEY>`. Group by epic, then by project key. Count resolved per epic. Note Highest and High priority items separately; they are usually moments.

## Watch for

- A project used as a queue (support, ops, bugs, security) is evidence of reliability and support work, not of features. Say which it is.
- Resolved is not done. Check `status` and drop Won't Do, Duplicate and Cannot Reproduce from the counts, or list them apart.
- Two people with the same display name: match on account id, never on the name.
- The MCP search has been seen to return a full page with no `nextPageToken`. If a result stops at exactly the page size, narrow the window and run again.
- Jira Data Center still uses `/rest/api/2/search` with `startAt` paging and a `total` field; check its own REST docs before reusing the loop above.
