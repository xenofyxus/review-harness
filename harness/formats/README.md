# Formats

One file per review type. The review workflow reads the format for the questions, the hints that shape follow-ups, and the checklist that shapes the draft review.

| File | For | Questions |
|---|---|---|
| `self.md` | Your own annual or half-year self review | 6 |
| `peer.md` | A colleague at your level | 4 |
| `manager.md` | Upward feedback on your manager | 6 |
| `report.md` | Someone who reports to you | 5 |
| `followup.md` | Goal and development follow-up between cycles | 6 |

## Using your company's questions

Copy any file to `workspace/formats/<type>.md`, replace the questions with the ones your HR tool shows, keep the hints and checklist or adapt them. The workspace copy wins over the harness copy. You can also just paste the questions into the chat when you start a review; the workflow will create the file for you.

## Structure of a format file

```
# Title                      shown to the owner
When to use                  one paragraph
## Questions                 numbered, quoted exactly as the form has them
## Hints                     per question: what a strong answer contains, follow-ups that work
## Draft checklist           type-specific things to flag before presenting
```
