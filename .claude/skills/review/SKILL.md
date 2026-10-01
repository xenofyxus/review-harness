---
name: review
description: "Start or resume a performance review interview (self, peer, manager, report, followup, or a custom format) and draft the review in the owner's own voice."
argument-hint: "<type> <slug>"
---

Follow `harness/workflows/review.md` exactly. Arguments: $ARGUMENTS. If that line shows a literal placeholder, the arguments are whatever the owner typed after the command.

`AGENTS.md` and the `harness/` directory sit at the root of this repository. If this skill was installed as a Claude Code plugin, they sit at `${CLAUDE_PLUGIN_ROOT}` instead; read that `AGENTS.md` first. Resolve the workspace from the folder you were started in as `AGENTS.md` says (that folder if it holds `config.yml`, else `workspace/` under it); it is never a folder inside the plugin.
