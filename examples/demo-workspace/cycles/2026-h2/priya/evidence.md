# Evidence for Priya Nair, 22 March 2026 to 22 September 2026

Compiled 22 September 2026 from GitHub (`gh` CLI, org `northwind-labs`), Linear (MCP connector, workspace `northwind`), Slack (MCP connector, channels the owner is a member of) and notes (`people/priya.md`). Everything below is what the systems show. What it means is for the interview.

## Volume

| | |
|---|---|
| Merged PRs | 48 (29 carrier-gateway, 11 webhook-dispatcher, 7 shipping-core, 1 infra) |
| PRs reviewed for others | 61, for 9 authors (14 for mayalq, 11 for tberg, 9 for lena-ohlin, 27 across six others) |
| Issues closed | 38 (18 Nordfrakt label API migration, 9 Webhook delivery reliability, 11 unprojected) |
| Notable incidents handled | 2 (12 May, 28 August) |

## Themes

### Nordfrakt label API migration (April to July)

Linear project "Nordfrakt label API migration", lead Priya Nair, 18 issues, 18 done, target date 1 July 2026, which is the date Nordfrakt shut off their old SOAP API. https://linear.app/northwind/project/nordfrakt-label-api-migration-3f9a1c2e

2 April: kickoff post in #backend with the milestone list and a date on each, thread kept updated weekly until cutover. https://northwind.slack.com/archives/C03B7KND2Q/p1775124911000000

14 April: carrier-gateway#412 "Add Nordfrakt REST client with token-bucket rate limiting". https://github.com/northwind-labs/carrier-gateway/pull/412

28 April: carrier-gateway#431 "Nordfrakt: label purchase and void via REST". https://github.com/northwind-labs/carrier-gateway/pull/431

19 May: carrier-gateway#447 "Nordfrakt: pickup booking via REST". https://github.com/northwind-labs/carrier-gateway/pull/447

8 to 12 June: BE-1907 "Customs declaration mapping for non-EU destinations" in progress for five days with no comments or linked PR until 12 June, then closed the same day as carrier-gateway#468 "Map customs declaration fields for non-EU shipments" (co-authored-by mayalq). https://linear.app/northwind/issue/BE-1907 and https://github.com/northwind-labs/carrier-gateway/pull/468

24 June: carrier-gateway#481 "Route Nordfrakt label purchases to REST client by default" merged 14:50; announcement in #shipping-launches at 15:30, 23 reactions. https://github.com/northwind-labs/carrier-gateway/pull/481 and https://northwind.slack.com/archives/C04L9NCH3P/p1782315011000000

9 July: carrier-gateway#493 "Remove Nordfrakt SOAP adapter", minus 4,120 lines. https://github.com/northwind-labs/carrier-gateway/pull/493

### Webhook delivery reliability (May to August)

12 May 09:14: Priya opens a thread in #incidents, webhook dispatcher stalled, tracking events not delivered to customers. She coordinates the thread, pulls in tberg and lena-ohlin, posts the all-clear at 09:58. Roughly 3,100 events delayed, all delivered by 10:30. https://northwind.slack.com/archives/C02N7CD8RK/p1778577251000000

13 May: postmortem document in Linear, author Priya Nair, three action items BE-1861, BE-1862, BE-1863 created unassigned. https://linear.app/northwind/document/postmortem-2026-05-12-webhook-dispatcher-stall-9c1e3a4f

4 June: tberg asks in #backend, right after standup, who owns the postmortem action items; all three assigned to Priya the same day. https://northwind.slack.com/archives/C03B7KND2Q/p1780567331000000

11 June: webhook-dispatcher#77 "Add persistent retry queue for webhook delivery" (BE-1861). https://github.com/northwind-labs/webhook-dispatcher/pull/77

25 June: webhook-dispatcher#84 "Dead-letter events after 8 attempts, alert on DLQ depth" (BE-1862). https://github.com/northwind-labs/webhook-dispatcher/pull/84

3 July: webhook-dispatcher#91 "Idempotency keys on outbound webhook payloads" (BE-1863). https://github.com/northwind-labs/webhook-dispatcher/pull/91

Linear project "Webhook delivery reliability", 9 issues, 9 done, last closed 14 August. https://linear.app/northwind/project/webhook-delivery-reliability-7b2d4e88

28 August: Velox Express tracking feed starts returning malformed timestamps at 12:40; Priya opens #incidents thread 13:02, webhook-dispatcher#118 "Tolerate malformed timestamps in Velox Express tracking feed" merged 14:47. https://northwind.slack.com/archives/C02N7CD8RK/p1787922131000000 and https://github.com/northwind-labs/webhook-dispatcher/pull/118

No delivery incidents in #incidents between 12 May and 22 September other than the Velox one.

### Reviews and knowledge sharing

61 PRs reviewed in the window, the highest count on the backend team (next highest 44). 14 of them on mayalq's PRs. Sample of review comments checked on carrier-gateway#502, #517 and shipping-core#1588: each has at least one comment starting "What happens if". https://github.com/northwind-labs/carrier-gateway/pull/517

30 June: thread in #backend, Priya proposes deleting the SOAP adapter at cutover rather than keeping it behind a flag; mayalq argues for a flag; outcome in thread: flag for two weeks, then delete. Deletion is carrier-gateway#493 on 9 July. https://northwind.slack.com/archives/C03B7KND2Q/p1782818411000000

20 August: lunch talk "Retries, idempotency and why our webhooks were dropping" announced in #backend, 18 reactions, recording linked in thread. Not cross-posted to #engineering. https://northwind.slack.com/archives/C03B7KND2Q/p1787227511000000

27 August: infra#203 "docs: retry and idempotency guidelines", the written version of the talk. https://github.com/northwind-labs/infra/pull/203

## Moments worth asking about

12 May, incident run from first message to all-clear in 44 minutes. https://northwind.slack.com/archives/C02N7CD8RK/p1778577251000000

8 to 12 June, BE-1907 quiet for five days, then closed after a co-authored PR. https://linear.app/northwind/issue/BE-1907

4 June, postmortem action items unassigned for three weeks until tberg asked. https://northwind.slack.com/archives/C03B7KND2Q/p1780567331000000

24 June, Nordfrakt cutover with a week to spare before the 1 July shutdown. https://northwind.slack.com/archives/C04L9NCH3P/p1782315011000000

30 June, public disagreement with the owner about the SOAP adapter, resolved in the thread with a date. https://northwind.slack.com/archives/C03B7KND2Q/p1782818411000000

20 August, lunch talk that stayed inside #backend. https://northwind.slack.com/archives/C03B7KND2Q/p1787227511000000

28 August, Velox timestamp fix merged within two hours of the first report. https://github.com/northwind-labs/webhook-dispatcher/pull/118

## Prompts for the interview

Q1: The Nordfrakt migration (18 issues, cutover 24 June) or the webhook retry work (12 May incident, three PRs, no incidents since)? Which one and why? What would have happened on 1 July without her on it?

Q2: BE-1907 sat in progress five days without a comment and closed the day you co-authored the PR. Is there something there? The postmortem action items sat unassigned three weeks until Tomas asked. Whose call was that?

Q3: 61 reviews, 14 on your PRs, every sample comment starts "What happens if". What is her review style like to be on the receiving end of? The 30 June SOAP adapter thread: how did that disagreement go and how did it end?

Q4: The 20 August talk got 18 reactions and never left #backend. Is there a next step there? Last cycle's development point was support tickets; the rotation from February is outside the window, did it land?

## Not found

Slack: #incidents-private not searched, the owner is not a member. Direct messages excluded by design. #shipping-support was searched for `from:` Priya and returned 3 messages in the window, down from what the 2025 review describes; not linked because none of them is notable on its own.

Linear: no issues for Priya in the "Critical issues" team in the window.

GitHub: no PR size analysis, since no small-PR goal is in play. No GitLab.

The February support rotation mentioned in `people/priya.md` is before the window and was not searched.
