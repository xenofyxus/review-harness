# Workflow: voice

Build or refresh `<workspace>/voice/profile.md`, the description of how the owner writes. The review workflow reads it before drafting. Without it, drafts follow the generic rules and sound generic.

## 1. Gather samples

Read everything in `<workspace>/voice/samples/`. Good samples, in order of value: reviews the owner wrote before, feedback they gave in writing, long Slack or email messages, design docs, retro notes. Ignore anything obviously written by someone else or by an AI, and say which files you skipped and why.

If there are no samples, do not guess. Ask the owner to paste two or three things they wrote, or point you at files. If they have nothing, run the short interview in step 3 and mark the profile as provisional.

## 2. Analyse

Read the samples as an editor would. Look for:

- **Tone.** Warm, blunt, dry, playful, formal. How they treat the reader.
- **Rhythm.** Sentence length, fragments, paragraph length, how answers open and close.
- **Vocabulary.** Words and constructions they reach for. Words that never appear.
- **Hard feedback.** What comes before a criticism, how it is phrased, what follows.
- **Hedging.** How often and how ("I think", "maybe", "to be fair").
- **References.** Frameworks, books, archetypes, running jokes.
- **Language mix.** If they write in more than one language, which one for what.

Collect verbatim examples for each. The profile is only useful if it quotes.

## 3. Ask three things

Even with good samples, ask, in one message:

1. Which phrases or habits do you hate seeing in your own writing?
2. Is there a review or piece of writing you are especially happy with, and what makes it good?
3. Anything the samples do not show, like how you write in a different language or to a different audience?

## 4. Write the profile

Fill `harness/templates/voice-profile.md` and save it to `<workspace>/voice/profile.md`. Quote generously. Keep it under a page and a half. End the `## Do not` section with the owner's own answers from step 3.

Show the profile in full and ask for corrections. Apply them exactly. The owner may tell you their writing is worse than it looks or better than it looks. Believe them; the profile describes how they want to sound.

## Done means

`voice/profile.md` exists, quotes real samples, and the owner has confirmed it reads like them.
