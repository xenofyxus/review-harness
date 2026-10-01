# Standalone prompts

One paste-in prompt per review format, for chat tools that cannot read files: a browser chat, a phone app, an internal bot, anything with only a text box.

Each file bundles `PREAMBLE.md`, `harness/principles.md`, `harness/workflows/review.md` and one format from `harness/formats/`. Nothing else. Evidence gathering, the voice workflow and the status view need file and tool access, so they are not available this way.

| File | Review type |
|---|---|
| `followup.md` | Performance and goals follow-up |
| `manager.md` | Manager review |
| `peer.md` | Peer review |
| `report.md` | Direct report review |
| `self.md` | Self review |

## Use

1. Open the file for the review type you need and copy all of it.
2. Paste it as the first message of a new chat, or as the system prompt if the tool has one.
3. Say `start`. The harness asks who the review is about and which language to write in, then interviews you one question at a time.
4. If you have a voice profile (`workspace/voice/profile.md`), paste it right after `start`. Without one, the harness follows the general writing rules only.

## Resume

Every reply that confirms an answer ends with a `Progress` block. To continue later, open a new chat, paste the prompt again, then paste the latest `Progress` block. The harness picks up from the first unanswered question.

Once a draft exists, the `Progress` block also names the current draft number. To resume during drafting or iteration, paste the `Progress` block and the latest draft text together. The harness continues iterating on that draft; it will ask for the draft if the block says one exists and none was pasted, and it never rebuilds a draft from the notes alone.

## Regenerate

These files are written by `scripts/build-adapters.sh` from `PREAMBLE.md` and the harness files. Edit those and run the script. Changes made directly to a generated file are lost on the next run.
