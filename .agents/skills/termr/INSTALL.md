# Install the termr skill

Copy the complete `termr` skill directory, including `SKILL.md`,
`references/`, and `assets/`, to one of these locations:

- **One repository:** `<repository>/.agents/skills/termr/`
- **All repositories:** `$CODEX_HOME/skills/termr/`, or
  `~/.codex/skills/termr/` when `CODEX_HOME` is not set.

For example, from a shell with this repository as the current directory:

```sh
mkdir -p /path/to/other-repository/.agents/skills
cp -R .agents/skills/termr /path/to/other-repository/.agents/skills/termr
```

Install `termr` separately in the R library used by the target project. No
other R package is required for the application template; `testthat` is
optional and is needed only when the project uses testthat tests.
