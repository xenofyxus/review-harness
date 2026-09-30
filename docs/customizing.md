# Customizing

Everything the harness does comes from markdown, so changing it means editing markdown. The workspace wins over the harness wherever both have a file, which keeps your changes out of the way of upstream updates.

## Use your company's questions

The built-in formats in [harness/formats/](../harness/formats/) are a starting point. Your HR tool almost certainly words things differently. Two ways to use its questions.

**Override in the workspace.** Copy the closest built-in format to `workspace/formats/<type>.md` and replace the questions, quoted exactly as the form shows them. Keep the hints and checklist, or adapt them. The review workflow reads the workspace copy first.

```sh
cp harness/formats/peer.md workspace/formats/peer.md
```

**Paste in chat.** Start the review and, when asked, paste the questions. The workflow writes them into `workspace/formats/<type>.md` in the built-in structure and continues.

## Write in another language

Set `language:` in `workspace/config.yml`. The writing rules in [principles.md](../harness/principles.md) apply in every language; the draft is written in the one you set.

```yaml
me:
  language: sv
```

The questions themselves are separate. Translated formats live under `harness/formats/<lang>/`, for example `harness/formats/<lang>/peer.md`. The review workflow reads `workspace/formats/<type>.md` first, so copy the translation there, or paste your form's questions as above. If you translate a format, consider sending it upstream; see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Adjust hints and checklists

Hints shape the follow-up questions. Checklists shape what the draft review flags. Both live in the format file, so edit them in your workspace copy. A hint is per question and reads like advice to an interviewer:

```markdown
**Q2.** Listen for a behaviour and a situation. Follow up with "have you told them?".
Our forms go to a calibration panel, so also ask what a reader outside the team would need to know.
```

A checklist line is one thing to flag:

```markdown
- Any mention of compensation. Our HR tool has a separate field for that.
```

## Edit the voice profile by hand

`workspace/voice/profile.md` is a document, not a database. If a draft does not sound like you, fix the profile rather than fixing the same sentence in every review. The most useful edits are verbatim: add a sentence of yours under "Words and phrases they use", add a habit you want gone under "Do not".

```markdown
## Do not

- Do not open an answer with the person's name. I never do that.
- Do not use "to be fair" more than once per review.
```

The voice workflow rewrites the profile when you rerun it with new samples, so mention your hand edits when you do, or paste them back in afterwards.

## Add a source

Sources are recipes in [harness/sources/](../harness/sources/), one file per system: how to detect it, what to query, what to write down, what to be careful with. [harness/sources/README.md](../harness/sources/README.md) describes the structure and how to add one. Once the file exists, add its name to `evidence.sources` in `config.yml` and the evidence workflow will try it in order.

```yaml
evidence:
  sources: [github, linear, slack, notion, notes]
```

## Add a review type

A review type is a format file. Create `workspace/formats/<type>.md` with the built-in structure (title, when to use, questions, hints, checklist), then point a review at it:

```yaml
reviews:
  - person: priya
    format: skip-level
```

Run `review skip-level priya`. Nothing else needs to know the type exists. If the type would be useful to other people, it belongs in `harness/formats/` with a pull request.

## Change the evidence window

The default is six months back from today. Change it in `config.yml`:

```yaml
evidence:
  window_months: 12
```

The evidence workflow states the window as dates before it searches, so you can also correct it once in chat ("start from 1 January instead") without editing anything.

Related: [how-it-works.md](./how-it-works.md), [evidence.md](./evidence.md), [harness/formats/README.md](../harness/formats/README.md).
