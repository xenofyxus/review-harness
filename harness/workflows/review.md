# Workflow: review

Start or resume one review. Interview the owner one question at a time, then draft, review and iterate until they mark it final.

**Arguments:** `<type> <slug>`. Type is a format name (`self`, `peer`, `manager`, `report`, `followup`, or a custom one). Slug is a person in `config.yml`, or `self`. If either is missing, look at `config.yml` `reviews:` and ask which one to work on. Accept loose input: "peer review for Priya" means `peer priya`.

## 1. Load context

Read, in this order. Stop and say so if a required file is missing.

1. `harness/principles.md`. Required.
2. `<workspace>/config.yml`. Required. Take the owner's name, language and current cycle.
3. `<workspace>/voice/profile.md`. If missing, say that the review will use the generic rules only and suggest running the voice workflow first. Do not block.
4. The format: `<workspace>/formats/<type>.md` if it exists, else `harness/formats/<type>.md`. If neither exists, ask the owner to paste the questions their company uses, write them into `<workspace>/formats/<type>.md` using the structure of `harness/formats/peer.md`, and continue.
5. `<workspace>/people/<slug>.md`. For `self`, this is optional. For anyone else, if missing, ask for a short background (role, how long you have worked together, relationship, anything relevant), save it from `harness/templates/person.md`, and continue.
6. `<workspace>/cycles/<cycle>/<slug>/progress.md`. If missing, create the folder and the file from `harness/templates/progress.md` with the format's questions listed.
7. `<workspace>/cycles/<cycle>/<slug>/evidence.md` and `notes.md` if they exist. Mark `evidence: yes` in progress if you read one.
8. Past reviews of this person or by the owner in `<workspace>/voice/samples/`, if any. Skim for history, do not copy.

## 2. Resume or start

If `progress.md` shows answered questions, summarise where things stand in three lines and continue from the first unanswered question. If a draft exists, go to step 5.

Otherwise, one short opening: what you are about to do, how many questions, that you will go one at a time, and that they can say "skip" or "come back to this". If evidence exists, say in one line what it covers so the owner knows you have it.

## 3. Interview

For each question in the format:

1. **Ask it.** Quote the question as written. If the format file has hints for this question, use them to shape what you are listening for, not to lecture. If evidence exists, add one or two concrete prompts from it, phrased as candidates, not conclusions.
2. **Follow up once or twice.** Aim at what is missing: the situation, what they did, the effect, the counterexample. Skip the follow-up if the answer already has it.
3. **Summarise and confirm.** Three to five sentences in plain prose, using their phrases. Ask if it is right. Accept corrections without argument.
4. **Save.** Append the confirmed notes under `## Notes` in `progress.md`, tick the question, set `status: in progress` and `updated:`. Do this before asking the next question, every time.

Rules while interviewing:

- Never ask two questions at once. Never present the whole questionnaire.
- If the owner answers several questions in one go, capture all of it, confirm, tick what is covered, and move on to what is not.
- If they go off on a tangent that is useful for a later question, note it under that question.
- Do not offer your own opinion of the person being reviewed.
- If the owner asks you to look something up (a PR, a date, a thread), do it and come back. Save what you found in `evidence.md`.

## 4. Draft

When every question is answered or skipped:

1. Set `status: drafting`.
2. Write the full review to `review.md` with a first line `<!-- draft 1 -->`. Structure: one title line, `# <Format title> for <Name>, <cycle>`, then the format's questions in bold, each followed by the answer in paragraphs. No other headers, no lists. Follow `harness/principles.md` and the voice profile. Write in the language from `config.yml`.
3. Run the draft review checklist from principles. Write the flags as a short list that lives in your message, not in the file.
4. Run the mechanical checks: em dashes, vocabulary list, bullet points inside answers, headers inside answers. Report in one line.
5. Present the full draft text and the flags together. The owner may not open the file, so the draft goes in the message in full.

## 5. Iterate

Apply the owner's changes exactly. Do not "improve" passages they did not mention. Bump the draft marker (`<!-- draft 2 -->`) and log one line under `## Draft history` in `progress.md`. Show the changed passages, not the whole text, unless they ask for the whole text.

If they push back on a flag you raised, drop it. If they ask "what do you think", answer in one or two sentences and then do what they decide.

## 6. Final

Only when the owner says it is final: remove the draft marker, set `status: final` and `updated:` in `progress.md`, and reply with the path. Offer, in one line, a plain-text copy without markdown for pasting into an HR form. Do not commit, push or send anything unless asked.

## Done means

`review.md` holds the text the owner approved. `progress.md` says `final`. Nothing in the review came from anywhere but the owner's words or evidence they accepted.
