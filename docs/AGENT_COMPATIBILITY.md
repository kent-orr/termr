# Agent compatibility

The canonical skill is `.agents/skills/termr/`. Its `SKILL.md`, references, and
template follow the open [Agent Skills specification](https://agentskills.io/specification).
Where an agent recognizes `.agents/skills`, keep this as the one project-level
copy. Other hosts can use an agent-specific path or an installer that copies
the same skill directory. Keep the relative `references/` and `assets/` files
with the skill.

## Supported hosts

Project paths below are documented by each host. The shared
`npx skills` commands are documented by the [Vercel Skills CLI](https://github.com/vercel-labs/skills),
but could not be executed during this audit because npm had no cached package
and network access was unavailable. Consequently, installer commands below
are documented, not runtime-verified here.

| Agent | Project skill path | User-level path | Installer agent ID | Activation and explicit use | Validation status |
| --- | --- | --- | --- | --- | --- |
| OpenAI Codex | `.agents/skills/termr/` | `~/.agents/skills/termr/` | `codex` | Select `termr` or invoke `$termr`; automatic selection depends on task relevance. | Path and invocation documented; no fresh-session benchmark run. |
| Claude Code | `.claude/skills/termr/` | `~/.claude/skills/termr/` | `claude-code` | Skills load when relevant; invoke `/termr` in Claude Code. | Path and invocation documented; Claude Code not installed/run here. |
| Cursor | `.agents/skills/termr/` or `.cursor/skills/termr/` | `~/.agents/skills/termr/` or `~/.cursor/skills/termr/` | `cursor` | Cursor discovers skills at startup. Select `/termr` from Agent's skill picker or ask the agent to use it. | Path and invocation documented; Cursor not installed/run here. |
| GitHub Copilot | `.agents/skills/termr/`, `.github/skills/termr/`, or `.claude/skills/termr/` | `~/.agents/skills/termr/` or `~/.copilot/skills/termr/` | `github-copilot` | Copilot chooses skills from prompt relevance. In Copilot CLI, invoke `/termr`; in other surfaces, ask the agent to use the termr skill. | Paths documented; no Copilot host run. Explicit slash support is documented for Copilot CLI, not all surfaces. |
| Gemini CLI | `.agents/skills/termr/` or `.gemini/skills/termr/` | `~/.agents/skills/termr/` or `~/.gemini/skills/termr/` | `gemini-cli` | Ask Gemini to use the termr skill. Check `/skills list`; `/skills enable termr` re-enables a disabled skill. Skill activation is agent-managed and can require consent; these management commands do not themselves invoke it. | Paths and management behavior documented; Gemini CLI not installed/run here. |
| OpenCode | `.agents/skills/termr/` or `.opencode/skills/termr/` | `~/.agents/skills/termr/` or `~/.config/opencode/skills/termr/` | `opencode` | OpenCode exposes available skills to its `skill` tool. Ask the agent to load `termr`; a slash command requires OpenCode-specific `opencode/slash` metadata, which this portable skill does not add. | Paths and tool behavior documented; OpenCode not installed/run here. |

## Installation commands

`npx skills` installs to project scope by default. Choose one supported target
at a time, or pass multiple agent IDs if desired:

```sh
npx skills add menshikovs/termr --list
npx skills add menshikovs/termr --skill termr --agent codex --copy
npx skills add menshikovs/termr --skill termr --agent claude-code --copy
npx skills add menshikovs/termr --skill termr --agent cursor --copy
npx skills add menshikovs/termr --skill termr --agent github-copilot --copy
npx skills add menshikovs/termr --skill termr --agent gemini-cli --copy
npx skills add menshikovs/termr --skill termr --agent opencode --copy
```

For user-level installation, add `--global`. The expected project locations
are agent-specific; check the resulting path before committing it. For manual
installation, copy the entire `.agents/skills/termr/` directory to the chosen
agent's project or user-level skill root shown above. For example, Claude Code
uses `.claude/skills/termr/` in a repository and `~/.claude/skills/termr/` for
personal use.

The Vercel CLI may prompt for agent selection and filesystem changes. Review
its output and confirm only the intended project-level installation. The
documented command here has not been executed successfully in this environment.

## Activation limits

All six hosts document Agent Skills support, but file-format compatibility does
not guarantee automatic activation. Automatic use depends on each host's skill
discovery, model choice, prompt, permissions, and settings. Explicit invocation
is host-specific; where no skill command is documented, ask the agent by name
and verify that it loaded the skill before relying on its instructions.

This repository validates the skill files and termr examples locally. It has
not run the six-agent benchmark in [AGENT_BENCHMARKS.md](AGENT_BENCHMARKS.md),
and does not claim identical runtime behavior across agents.

## Official host documentation

- [Agent Skills specification](https://agentskills.io/specification)
- [Codex skills](https://developers.openai.com/codex/skills)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Cursor Agent Skills](https://cursor.com/docs/skills)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [Gemini CLI Agent Skills](https://geminicli.com/docs/cli/using-agent-skills/)
- [OpenCode Agent Skills](https://opencode.ai/docs/skills)
- [Vercel Skills CLI](https://github.com/vercel-labs/skills)
