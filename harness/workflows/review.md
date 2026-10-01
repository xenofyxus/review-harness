# Workflow: review

Start or resume one review. Interview the owner one question at a time, then draft, review and iterate until they mark it final.

**Arguments:** `<type> <slug>`. Type is a format name (`self`, `peer`, `manager`, `report`, `followup`, or a custom one). Slug is a person in `config.yml`, or `self`. If either is missing, look at the `reviews:` list in `config.yml` and ask which one to work on. Accept loose input: "peer review for Priya" means `peer priya`.

## 1. Load context

Resolve the workspace as `AGENTS.md` says, then read, in this order. Stop and say so if a required file is missing.

1. `harness/principles.md`. Required.
2. `<workspace>/config.yml`. Required. If it is missing, stop, say so and suggest the `setup` workflow. Do not run setup unless the owner asks. Take the owner's name, language and current cycle.
3. `<workspace>/voice/profile.md`. If missing, say that the draft will follow the generic rules only and suggest the `voice` workflow. Do not block.
4. The format: `<workspace>/formats/<type>.md` if it exists, else `harness/formats/<type>.md`. If neither exists, ask the owner to paste the questions their form uses, write them into `<workspace>/formats/<type>.md` with the questions filled in and the Hints and Draft checklist sections copied from the closest built-in format, and continue. If the owner pastes questions at any later point, or says their form differs, do the same and use that file from then on.
5. `<workspace>/people/<slug>.md`. Optional for `self`. For anyone else, if missing, ask for a short background (role, how long you have worked together, relationship, anything relevant), save it from `harness/templates/person.md`, and continue.
6. `<workspace>/cycles/<cycle>/<slug>/progress.md`. If missing, create the folder and the file from `harness/templates/progress.md`: the format's questions shortened to their first clause, `status: not started`, and no placeholder text left in.
7. `<workspace>/cycles/<cycle>/<slug>/evidence.md` and `notes.md`, if they exist. Set `evidence: yes` in `progress.md` once you have read an evidence file.
8. Past reviews of this subject, or by the owner, in `<workspace>/voice/samples/`, if any. Skim for history and for the development feedback given last time. Do not copy.

## 2. Resume or start

If `progress.md` shows answered or skipped questions, summarise where things stand in three lines and continue from the first question that is neither. If a draft exists, go to step 5.

Otherwise, one short opening: what you are about to do, how many questions, which file the questions come from and that the owner can paste different ones now, that you will go one at a time, and that they can say "skip", "come back to this" or "off the record". If evidence exists, say in one line what it covers.

## 3. Interview

For each question in the format:

1. **Ask it.** Quote the question as written. If the format file has hints for this question, use them to shape what you are listening for, not to lecture. If evidence exists, add one or two concrete prompts from it, phrased as candidates, not conclusions.
2. **Follow up once or twice.** Aim at what is missing: the situation, what they did, the effect, the counterexample. Skip the follow-up if the answer already has it.
3. **Summarise and confirm.** Three to five sentences in plain prose, using their phrases. Ask if it is right. Accept corrections without argument.
4. **Save.** Append the confirmed notes under `## Notes` in `progress.md` as a block headed by the question number, replacing any placeholder text. Tick the question. Set `status: in progress`, `started:` on the first save, and `updated:` on every save. Do this before asking the next question, every time.

Rules while interviewing:

- Never ask two questions at once. Never present the whole questionnaire.
- If the owner answers several questions in one go, capture all of it, confirm, tick what is covered, and move on to what is not.
- If they go off on a tangent that is useful for a later question, note it under that question.
- If the owner skips a question, tick it and write `skipped` as its note, so a resumed session does not ask it again.
- If the owner says something is off the record, prefix it with `off the record:` in the notes and keep it out of the draft.
- Do not offer your own opinion of the subject.
- If the owner asks you to look something up (a PR, a date, a thread), do it and come back. Save what you found in `evidence.md`.

## 4. Draft

When every question is answered or skipped:

1. Set `status: drafting`.
2. Write the full review to `review.md` with a first line `<!-- draft 1 -->`. Structure: one title line, `# <Format title> for <Name>, cycle <cycle>`, then each answered question in bold, followed by the answer in paragraphs. Leave skipped questions out and say in the flags which ones are missing. No other headers, no lists. Follow `harness/principles.md` and the voice profile. Write in the language from `config.yml`.
3. Review the draft against the checklist under "Reviewing the draft" in `harness/principles.md` and the "Draft checklist" of the format. Write the flags as a short list in your message, not in the file.
4. Run the mechanical checks: em dash character, vocabulary list, lists or headers inside answers. Report in one line.
5. Add a line under `## Draft history` in `progress.md`: the date and "draft 1".
6. Present the full draft text and the flags together. The owner may not open the file, so the draft goes in the message in full.

## 5. Iterate

Apply the owner's changes exactly. Do not "improve" passages they did not mention. Bump the draft marker (`<!-- draft 2 -->`) and log one line under `## Draft history` in `progress.md`. Show the changed passages, not the whole text, unless they ask for the whole text.

If they push back on a flag you raised, drop it. If they ask "what do you think", answer in one or two sentences and then do what they decide.

## 6. Final

Only when the owner says it is final: remove the draft marker, set `status: final` and `updated:` in `progress.md`, and reply with the path. Offer, in one line, a plain-text copy without markdown for pasting into an HR form. Do not commit, push or send anything unless asked.

## Done means

`review.md` holds the text the owner approved. `progress.md` says `final`. Nothing in the review came from anywhere but the owner's words or evidence they accepted.
