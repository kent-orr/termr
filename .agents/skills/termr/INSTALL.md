# Install the termr skill directory

Install or copy the complete `termr` directory, preserving `SKILL.md`,
`references/`, and `assets/`. Place it under a skill root recognized by your
agent. Repository-level instructions and exact locations for supported agents
are maintained in the termr repository at `docs/AGENT_COMPATIBILITY.md`.

If copying manually, copy the directory itself into the host's `skills/`
directory; do not copy only `SKILL.md`, since it links to bundled references
and an application template.

Install the `termr` R package separately in the target project's R library.
The application template uses only termr; `testthat` is optional and is
needed only when running the testthat recipe.
