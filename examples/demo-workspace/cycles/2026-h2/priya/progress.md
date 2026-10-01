# Peer review for Priya Nair

status: final              # not started | in progress | drafting | final
person: priya
format: peer
cycle: 2026-h2
started: 2026-09-24
updated: 2026-09-25
evidence: yes              # yes once evidence.md exists and has been read

## Questions

1. [x] Strengths in the past 6 months, with one example
2. [x] Skills or behaviours to develop, with the situation behind it
3. [x] Collaboration: what worked, what could have gone better, with an example
4. [x] Anything else for their growth or effectiveness

## Notes

**Q1.** Nordfrakt migration is the one, "the thing I'd point to". Nordfrakt's 1 July shutdown was a real deadline, not a planning one. Priya owned it from April: wrote the plan on 2 April with a date per milestone, kept the #backend thread updated weekly, did the rate-limited REST client first because that was the piece nobody had done before. Customs mapping was "the ugly bit nobody wanted". Cutover 24 June, "a week to spare". Follow-up "what would have happened without her": Maya thinks they would have reached 1 July with the SOAP adapter still in production and a very bad week, because nobody else had the carrier context to do it in the time. Not the code that made it work but "she treated the date as real from day one". Second strength, shorter: webhook work after 12 May. Ran the incident, wrote the postmortem next day, then fixed the actual problem (retry queue, dead-lettering after eight attempts, idempotency keys) rather than adding an alert. Maya's phrase: "boring, unglamorous, exactly right". No delivery incident since. Accepted from evidence: the count of 18 tickets, which Maya did not say herself.

**Q2.** Goes quiet on hard problems. Example: BE-1907 customs mapping, Monday 8 to Friday 12 June, no comment for five days. Came up in Friday standup, paired that afternoon, done by end of day. Maya: "not because I knew the answer, saying the problem out loud is half of solving it". Counterexample offered by Maya without prompting: 12 May, she pulled people in within minutes. So it is "slow-burn problems, the ones with no alarm attached", not pressure. Wish: after a day of being stuck, say so in the thread. Has she told Priya: yes, in person, week after, so "it will not be a surprise". Why it matters: Maya thinks this is the one thing between Priya and the next level of scope. Postmortem action items prompt: Maya says that one is on both of them, belongs under Q3, not here.

**Q3.** Worked well: reviews. Every review has a "what happens if" question. Examples Maya gave: what happens if the carrier returns a 429 mid-batch, what happens if the same event arrives twice. Maya "stopped being annoyed because they are right often enough" and now asks them herself before opening a PR. "That is the best kind of review culture and she built most of it." Disagreement: SOAP adapter, 30 June. Priya wanted it deleted at cutover, Maya wanted a flag for rollback. Argued in the thread, landed on two weeks behind a flag then hard delete, Priya deleted it 9 July. Maya: "how I want disagreements to go, quickly, in the open, with a date attached". Could have gone better: postmortem action items unassigned three weeks, "we each assumed the other was tracking them", Tomas had to ask on 4 June. Fixed since (action items get an owner in the postmortem doc now). Maya wants it in as "on both of us". Accepted from evidence: 61 reviews, 14 of them Maya's.

**Q4.** Last year's Q4 was "take the lead on the next carrier integration". She did, "went better than I expected". Next: the 20 August lunch talk was "the clearest explanation of retries I have heard at Northwind" and it stayed in #backend. Maya wants her to take it to the engineering forum, because the frontend and data teams have the same problem "and do not know it yet". Support rotation: Priya set it up in February, it stuck, Maya's 2025 development point is resolved. "Her project time is hers again. Keep it that way." Maya asked to end on that.

## Draft history

2026-09-24, draft 1: full draft after the interview, about 760 words, seven flags raised, Maya kept both evidence numbers (18 tickets, 61 reviews), kept the three-paragraph answers, and dropped the "too soft" flag on Q2 by rewriting the opening sentence herself.
2026-09-25, draft 2: Q2 opening replaced with Maya's wording ("When a problem is hard, you tend to disappear into it. I do the same, so I recognise it."), no other changes, marked final.
