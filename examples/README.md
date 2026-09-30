# Examples

A filled-in workspace and a transcript, so you can see what the harness produces before you run it on your own colleagues.

**Everything here is fictional.** Maya Lindqvist, Priya Nair, Tomas Berg, Northwind Labs, Nordfrakt, Velox Express, every link, number, PR and Slack thread: all invented for the demo. Nothing describes a real person or a real company. Keep it that way if you add to it.

## What is here

| Path | What it shows |
|---|---|
| `demo-workspace/config.yml` | A complete config: owner, two people, three reviews, evidence settings with handles filled in. |
| `demo-workspace/people/` | Person files for a peer (`priya.md`) and a manager (`tomas.md`), including the "things I want to remember" notes the evidence workflow reads. |
| `demo-workspace/voice/samples/` | One past review the owner wrote, the raw material for the voice profile. |
| `demo-workspace/voice/profile.md` | The voice profile the voice workflow built from that sample, quoting it. |
| `demo-workspace/cycles/2026-h2/priya/evidence.md` | What the evidence workflow found for Priya across GitHub, Linear and Slack: volume, themes, moments, prompts per question, gaps. |
| `demo-workspace/cycles/2026-h2/priya/progress.md` | Interview state after the review was marked final: ticked questions, faithful notes per answer, draft history. |
| `demo-workspace/cycles/2026-h2/priya/review.md` | The final peer review, in Maya's voice. |
| `transcript.md` | A condensed transcript of the interview that produced it. |

Only the peer review for Priya is worked through. The self review and the manager review for Tomas are listed in `config.yml` and not started, which is what a real workspace looks like mid-cycle.

## How to read it

Start with the voice sample, then the profile. The sample is what Maya sounds like; the profile is how the harness describes that sound to itself. If the profile did not quote the sample, it would be useless, so notice how much of it is verbatim.

Then read `evidence.md`. Every line carries a link and none of them interprets. "BE-1907 in progress for five days with no comments" is evidence. "She struggles to ask for help" would not be. The last two sections, moments and prompts, are what the interviewer actually uses.

Then read `transcript.md` and `progress.md` side by side. The transcript shows the interview; the progress notes show what was saved after each confirmed answer. The notes keep Maya's phrases ("boring, unglamorous, exactly right") because those phrases are what make the draft sound like her.

Finally read `review.md` and check it against the notes. Nothing in the review came from anywhere else. The numbers that came from evidence rather than from Maya's mouth were flagged in the transcript and she chose to keep them.

## What to look for

The development point in question 2 is the part worth studying. It names a behaviour, a dated situation, a counterexample from the same period, a wish, and why it matters, in three short paragraphs. It reads as wanting Priya to do well. The first sentence is one Maya rewrote herself after the harness flagged the draft as too soft; the transcript shows the exchange.

Also notice what the harness does not do. It does not offer an opinion of Priya. It does not add the 3,100 delayed events from the evidence file, because Maya never mentioned them. It does not mark the review final until Maya says so.

## Trying it yourself

Copy `demo-workspace/` over `workspace/` in a scratch checkout, then ask your harness to run the status workflow. You should see one final review and two not started. Run `review manager tomas` to interview yourself as Maya and see how a session starts from a blank progress file.
