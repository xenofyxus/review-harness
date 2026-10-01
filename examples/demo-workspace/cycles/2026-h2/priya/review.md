# Peer review for Priya Nair, cycle 2026-h2

**What strengths has this person demonstrated in the past 6 months, and how have they contributed to the work or team? Please include one specific example.**

The thing I'd point to is the Nordfrakt migration. Nordfrakt gave us a shutdown date for their old label API, 1 July, and you owned getting us off it. Eighteen tickets, a new client with proper rate limiting, and the customs field mapping for non-EU shipments that nobody wanted to touch. We cut over on 24 June with a week to spare. No customer noticed, which was the point.

What made it work was not the code, though the code is good. It was that you treated the date as real from day one. You wrote the plan on 2 April with a date on every milestone, did the rate-limited client first because it was the piece nobody had done before, and kept the thread in #backend updated so the rest of us knew where things stood without asking. Without you on it, I think we would have hit July with the SOAP adapter still in production and a very bad week ahead of us. Nobody else had the carrier context to do it in the time.

The other one is the webhook work. When the dispatcher stalled on 12 May you ran the incident, wrote the postmortem the next day, and then fixed the underlying problem instead of adding an alert and moving on: a persistent retry queue, dead-lettering after eight attempts, idempotency keys on the payloads. Boring, unglamorous, exactly right. We have not had a delivery incident since.

**What skills or behaviors could this person further develop to be even more effective? Share an example or situation that informed your feedback.**

When a problem is hard, you tend to disappear into it. I do the same, so I recognise it. The example I keep coming back to is the customs mapping ticket in June. It sat in progress from the Monday to the Friday without a comment. When it came up in standup on the Friday and we paired for an afternoon, it was done by the end of the day. Not because I knew the answer. Saying the problem out loud is half of solving it.

Pressure is not the problem. On 12 May you pulled people in within minutes. It is the slow-burn problems, the ones with no alarm attached, where you go quiet. After a day of being stuck, I would rather you said so in the thread. Nobody will think less of you. The opposite, actually.

I told you this in person the week after, so it will not be a surprise. I am writing it down because it is the one thing between you and the next level of scope, and I would like you to get there.

**How has collaboration with this person been over the past 6 months? What worked well, and what, if anything, could have gone better? Please include an example.**

Reviews are where I see you most. You reviewed sixty-one PRs this period, fourteen of them mine, and every one had a "what happens if" in it. What happens if the carrier returns a 429 mid-batch. What happens if the same event arrives twice. I stopped being annoyed by these a while ago, because they are right often enough that I now ask them myself before I open the PR. That is the best kind of review culture, and you built most of it.

We disagreed properly once, about the SOAP adapter. You wanted it deleted the day we cut over. I wanted a flag so we could roll back. We argued it out in a thread on 30 June, landed on two weeks behind a flag and then a hard delete, and you were the one who deleted it on 9 July. That is how I want disagreements to go: quickly, in the open, with a date attached.

What could have gone better is on both of us. The postmortem action items from May sat unassigned for three weeks because we each assumed the other was tracking them, and Tomas had to ask in standup. Small thing, and we have fixed it, action items get an owner in the postmortem doc now. I would still rather we had caught it ourselves.

**Is there any additional feedback you'd like to share that would be helpful for this person's growth or effectiveness?**

Last year I wrote that you should take the lead on the next carrier integration. You did, and it went better than I expected. So here is the next one. The lunch talk you gave in August on retries and idempotency was the clearest explanation of that problem I have heard at Northwind, and it stayed inside #backend. Take it to the engineering forum. The frontend and data teams have the same problem and do not know it yet.

And the support rotation you set up in February fixed the thing I flagged last year. Your project time is yours again. Keep it that way.
