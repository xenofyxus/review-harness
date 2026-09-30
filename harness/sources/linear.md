# Source: Linear

Issues assigned to or created by the subject, projects they led, milestones they closed.

## Detect

Prefer a Linear MCP connector if the harness has one (look for tools named like `list_issues`, `list_projects`, `get_user`). Otherwise use the GraphQL API with a personal key in `LINEAR_API_KEY`:

```sh
test -n "$LINEAR_API_KEY" && echo linear-ok
```

If neither, skip and note it.

## Queries

**Issues touched in the window**, assignee = subject, updated after the window start, 250 at a time. Keep id, title, status, project, team, completedAt, labels, priority. Sort by completedAt.

MCP: `list_issues` with `assignee: "<name or me>"`, `updatedAt: "<SINCE>"`, `limit: 250`, fields `id,title,status,project,completedAt,team,priority,labels`.

GraphQL:

```sh
curl -s https://api.linear.app/graphql -H "Authorization: $LINEAR_API_KEY" -H 'Content-Type: application/json' \
  -d '{"query":"{ issues(first: 250, filter: { assignee: { email: { eq: \"<email>\" } }, updatedAt: { gte: \"<SINCE>\" } }) { nodes { identifier title completedAt state { name } project { name } team { key } priority labels { nodes { name } } } } }"}'
```

**Projects the subject is a member of or leads**, updated in the window. Keep name, lead, status, start and target dates, milestones and their progress. A project with the subject as lead is a theme by itself.

MCP: `list_projects` with `member: "<name or me>"`, `updatedAt: "<SINCE>"`, `includeMilestones: true`.

**Issues in a project**, when a project looks important: `list_issues` with `project: "<name>"` to count done versus open.

## What to write down

Issue id, title, project, completed date, and the URL pattern `https://linear.app/<workspace>/issue/<id>`. Group by project. Count done per project. Note priority "Urgent" items separately; they are usually moments.

## Watch for

- Issues in a triage or "errors" project: evidence of reliability work.
- Issues in a "critical issues" team: evidence of support and incident handling.
- Projects with the subject as lead: ask about them first in the interview.
