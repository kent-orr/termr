# Agent skill benchmarks

This is a reproducible protocol for evaluating whether termr's skill helps
coding agents. Do not report a host as passing until its run has been recorded
with the required artifacts. Current compatibility claims describe documented
file support only; benchmark outcomes are untested.

## Task prompt

Use the same prompt for each agent in a clean temporary R project:

> Build an interactive full-screen terminal dashboard in R with keyboard
> navigation, a sortable table, and automated interaction tests. Use the
> project's installed packages and verify the app headlessly.

Install the termr skill in the host's documented project-level location before
the run. Do not mention the skill in the initial task prompt. Start a fresh
agent session with no unrelated skill copies. Ensure R and termr are available
to the temporary project. Record the exact host, version, model, OS, install
path, initial prompt, transcript, generated files, and command output.

## Evaluation steps

Record each dimension as `Pass`, `Partial`, `Fail`, or `Not tested`, with
evidence:

1. **Discovery:** Does the host list or otherwise expose the installed skill?
2. **Automatic activation:** With no skill named in the prompt, does the agent
   load or use it? Record explicit permission prompts separately.
3. **Framework selection:** Does the agent choose termr for this R full-screen
   TUI task?
4. **Public API accuracy:** Do generated calls and arguments exist in the
   installed public API? Check the termr help, `NAMESPACE`, and stability guide.
   Fail for undocumented internal calls such as `termr:::`.
5. **Application startup:** Does the application start in a real terminal and
   exit normally? Capture terminal, OS, and command. A headless test is not a
   real-terminal startup check.
6. **Headless interaction:** Do automated tests exercise keyboard navigation,
   sorting, and visible screen output using `test_app()` and pass without
   snapshot regeneration used just to make a test pass?

## Recording template

| Agent and version | Discovery | Automatic activation | Selected termr | Public API | Real-terminal startup | Headless interaction | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Codex | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |
| Claude Code | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |
| Cursor | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |
| GitHub Copilot | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |
| Gemini CLI | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |
| OpenCode | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | |

Retain the transcript and generated project for every run. Repeat the test at
least once per host after changing the skill description or its core workflow.
Report documented compatibility separately from measured benchmark results.
