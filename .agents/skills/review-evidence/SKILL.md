---
name: review-evidence
description: "Gather evidence of a person's work from GitHub, GitLab, Linear, Jira, Slack and notes, theme it with links, and produce interview prompts."
argument-hint: "<slug>"
---

Follow `harness/workflows/evidence.md` exactly. Arguments: $ARGUMENTS. If that line shows a literal placeholder, the arguments are whatever the owner typed after the command.

`AGENTS.md` and the `harness/` directory sit at the root of this repository. If this skill was installed as a Claude Code plugin, they sit at `${CLAUDE_PLUGIN_ROOT}` instead; read that `AGENTS.md` first. The workspace is the folder you were started in, never a folder inside the plugin.
