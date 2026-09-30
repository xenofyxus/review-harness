# Source: Slack

The messiest source and the richest for moments: announcements, decisions, public pushback, thanks. Use it after GitHub and Linear so you can search by project names you already know.

## Detect

Prefer a Slack MCP connector (tools named like `search_messages`, `slack_search_public_and_private`). Otherwise the Web API with a user token in `SLACK_USER_TOKEN` (scope `search:read`):

```sh
test -n "$SLACK_USER_TOKEN" && curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" https://slack.com/api/auth.test
```

If neither, skip and note it.

## Searches

Run these as separate searches. Slack search is lexical; combine a user filter with one modifier or one keyword at a time. Use the subject's member ID (`U...`) in `from:`.

1. **Reacted messages.** `from:<@ID> has:reaction after:<SINCE>`, sorted by relevance. What people react to is what mattered.
2. **Threads started.** `from:<@ID> is:thread after:<SINCE>`.
3. **By project.** For each theme found in GitHub and Linear: `from:<@ID> <project keyword> after:<SINCE>`. Also without the `from:` filter, to see announcements and reactions from others.
4. **Announcements and release notes.** Keywords like `launch`, `live`, `shipped`, `release`, `merged`, in the channels the org uses for that.
5. **Talks and forums.** `<subject first name>` in channels about forums, all-hands, guilds, demos, sorted by relevance. Also `-from:<@ID> <first name> has:reaction` to find what others said about them.
6. **Pushback and decisions.** Keywords like `proposal`, `decision`, `pre-read`, `trade-off`, `I disagree`, `we should`.
7. **Incidents.** `incident`, `hotfix`, `down`, `outage`, `rollback`, with and without `from:`.

Web API equivalent for any of these:

```sh
curl -s -G https://slack.com/api/search.messages -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  --data-urlencode 'query=from:<@ID> has:reaction after:<SINCE>' --data-urlencode 'sort=score' --data-urlencode 'count=20'
```

Page through results while they stay relevant. Twenty to forty good messages beat four hundred noisy ones.

## What to write down

Date, channel, one-line gist, permalink. Quote at most a sentence. Skip anything that is chit-chat, scheduling or a link with no context. Mark messages from the subject's own automated digests or bots as such, or drop them.

## Be careful

- Only channels the owner is a member of. Do not try to read anything else.
- For a review of someone else, do not include content from the owner's private messages with third parties about the subject.
- Names of two people can collide (two Antons, two Sams). Check the user ID before attributing a message.
