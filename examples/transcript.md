# Transcript: peer review for Priya, cycle 2026-h2

A condensed record of the interview that produced `demo-workspace/cycles/2026-h2/priya/review.md`. Everything in it is fictional. The owner is Maya Lindqvist; "Harness" is whichever AI harness is running the review workflow. Questions 2 and 3 are summarised rather than reproduced, and the draft is not repeated in full, since it is the file next door. What remains shows the shape of a good session. The harness asks one question at a time and offers evidence as prompts rather than conclusions. It summarises before every save and puts its flags under the draft. The owner decides what is final.

The session was started with `review peer priya`.

---

**Harness:** I have read the principles, `config.yml`, your voice profile, the peer format, `people/priya.md`, the evidence from 22 September and your 2025 review of her. The evidence covers 22 March to 22 September from GitHub, Linear and Slack: the Nordfrakt migration, the webhook reliability work, and her reviews and lunch talk. Last year's development point was support tickets, and her people file says a rotation happened in February, so I will ask about that under question 4.

Four questions, taken from `harness/formats/peer.md`. If your form uses different ones, paste them now and I will use those instead. One at a time: after each answer I will follow up once or twice, summarise, and ask you to confirm before I save. Say "skip", "come back to this" or "off the record" at any point. Ready when you are.

**Maya:** Go.

**Harness:** Question 1, as written: "What strengths has this person demonstrated in the past 6 months, and how have they contributed to the work or team? Please include one specific example."

Two candidates from the evidence, and they are only candidates. The Nordfrakt migration: 18 issues, all done, cutover on 24 June, a week before the 1 July shutdown. Or the webhook work: the 12 May incident, the postmortem, three PRs, and no delivery incident since. Which one is it for you, and why?

**Maya:** Nordfrakt. It is the thing I'd point to. The shutdown was a real date, not a planning date, and she owned getting us off the old API. She wrote the plan on 2 April with a date on every milestone and kept the thread in #backend updated every week so nobody had to ask where it stood. She did the rate-limited REST client first because that was the piece nobody had done before. The customs mapping was the ugly bit nobody wanted to touch. And we cut over on 24 June with a week to spare. No customer noticed, which was the point.

**Harness:** What would have happened on 1 July without her on it?

**Maya:** We would have hit July with the SOAP adapter still in production and a very bad week ahead of us. Nobody else had the carrier context to do it in the time. Honestly it was not the code that made it work, though the code is good. It was that she treated the date as real from day one.

The webhook work is the other one, but shorter. She ran the incident on 12 May, wrote the postmortem the next day, and then fixed the actual problem instead of adding an alert and moving on. Retry queue, dead-lettering after eight attempts, idempotency keys. Boring, unglamorous, exactly right. We have not had a delivery incident since.

**Harness:** Here is what I have. The Nordfrakt migration is the example. She owned it from the plan on 2 April to the cutover on 24 June, with a date per milestone and a weekly thread, and she did the rate-limited client first because it was the unknown piece. Without her, you think July would have arrived with the SOAP adapter still live and a very bad week. What made it work was that she treated the date as real, not the code as such. Second strength, briefer: the webhook work after 12 May, incident, postmortem, then a real fix rather than an alert, and no delivery incident since. Is that right?

**Maya:** Yes. Keep "boring, unglamorous, exactly right", that is how I want it.

**Harness:** Saved to `progress.md`, question 1 ticked. For the record, the count of 18 tickets came from the evidence file, not from you, so I will mark it in the draft flags.

---

*Questions 2 and 3 went the same way: the question quoted as written, one or two prompts from the evidence, a follow-up aimed at what was missing, a summary, a confirmation, a save. For question 2 the evidence prompt was BE-1907 sitting five days without a comment, and the follow-up was "is there a moment where the opposite was true?", which produced the 12 May counterexample. Maya moved the unassigned postmortem action items from question 2 to question 3 because "that one is on both of us". The notes for both are in `progress.md`.*

---

**Harness:** Question 4, as written: "Is there any additional feedback you'd like to share that would be helpful for this person's growth or effectiveness?"

Two things from the file. The 20 August lunch talk got 18 reactions and stayed inside #backend, never cross-posted. And last year's development point about support tickets: the February rotation is outside the evidence window, but you mentioned it in her people file. Did it land?

**Maya:** Both, yes. Start with last year. I wrote that she should take the lead on the next carrier integration. She did, and it went better than I expected. So here is the next one. That talk was the clearest explanation of retries and idempotency I have heard at Northwind, and it stayed in one channel. She should take it to the engineering forum. Frontend and data have the same problem and do not know it yet.

And the rotation: she set it up in February, it stuck, and my point from last year is done. Her project time is hers again. I want to end on that. Keep it that way.

**Harness:** Captured. Last year's suggestion, lead a carrier integration, happened and went better than expected. Next step: take the August talk to the engineering forum because frontend and data have the same problem without knowing it. The support rotation from February resolved the 2025 development point, and the review should end on "your project time is yours again, keep it that way". Correct?

**Maya:** Correct.

**Harness:** Saved, question 4 ticked. All four are answered. Setting status to drafting and writing the review now.

---

**Harness:** Draft 1 is in `review.md`, about 760 words. Here is the full text.

*[Draft 1 shown in full here. It is identical to the final `review.md` except for the first two sentences of question 2, which read: "One thing I would like to see you work on is asking for help earlier when a problem is hard. I say this as someone who does the same."]*

Flags, reading it as Priya, then as you, then as a sceptical HR reader:

- Not theirs: "eighteen tickets" in Q1 and "sixty-one PRs, fourteen of them mine" in Q3 come from the evidence file. You confirmed both. Say the word and I cut either.
- Too soft: the opening of Q2, "One thing I would like to see you work on", is a cushion. Your profile says you state the behaviour flat in the first sentence. Want it sharper?
- Missing context: a reader outside the team will not know what "the SOAP adapter" is. Q1 says "old label API" before it says SOAP adapter, which may be enough. Your call.
- Contradictory: Q1 praises how she ran the 12 May incident, Q2 says she goes quiet. Q2 names 12 May as the counterexample, so they fit. No change proposed.
- Voice: Q1, Q2 and Q3 each run to three paragraphs, the top of the range in your profile, and the 2025 review never went past two. Say the word and I trim Q1 or Q3.
- Voice: Q4 ends on two short sentences, which matches your closes, and "Small thing, and we have fixed it" in Q3 is yours from the interview. Nothing to fix.
- Only she does: the "what happens if" reviews. That could not be pasted into anyone else's review.

Mechanical checks: no em dashes, no words from the vocabulary list, no lists or headers inside answers.

**Maya:** Keep both numbers. The SOAP adapter is fine, Tomas knows what it is and so does she. Leave the length. On Q2, you are right that it is soft, but the fix is not "sharper", it is that the sentence is not mine. Make it: "When a problem is hard, you tend to disappear into it. I do the same, so I recognise it." Then straight into the customs example.

**Harness:** Applied exactly, nothing else touched. The changed passage:

"When a problem is hard, you tend to disappear into it. I do the same, so I recognise it. The example I keep coming back to is the customs mapping ticket in June. It sat in progress from the Monday to the Friday without a comment."

Marker bumped to draft 2 and one line added under draft history in `progress.md`. Anything else?

**Maya:** No. That is final.

**Harness:** Draft marker removed, `status: final` and `updated: 2026-09-25` set in `progress.md`. The review is at `cycles/2026-h2/priya/review.md`. If you want a plain-text copy without the bold questions for pasting into the HR form, say so and I will print it.

**Maya:** Not needed. Thanks.
