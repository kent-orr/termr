# GitHub community setup (maintainer)

Repository files provide contributor guidance and templates; they do not change
GitHub settings. Apply the settings below manually as repository administrator.
No remote changes were made as part of this setup.

## Observed state

Read-only inspection on 2026-10-21 found:

- Default branch: `main`; Issues and Discussions are enabled.
- Private Vulnerability Reporting: **disabled** (`enabled: false`).
- The five established labels in the table below already exist. The other
  three requested labels are missing.
- The branch endpoint marks `main` as protected, but its embedded classic
  protection data reports disabled enforcement and no required checks.
  This does not establish the effective ruleset configuration; inspect it in
  Settings before changing anything.
- The repository metadata available to this inspection did not expose merge
  method settings. Verify them in Settings.

Recheck current state before configuring; this is a dated observation.

## Security reporting and Discussions

1. In **Settings > Advanced Security**, enable **Private vulnerability reporting**.
   Confirm the [private report form](https://github.com/menshikovs/termr/security/advisories/new)
   is available. Update the dated disabled-status paragraph in
   [SECURITY.md](../SECURITY.md) after enabling it.
2. Keep **Discussions** enabled under **Settings > General > Features** for
   questions, usage help, and early ideas. Keep Issues enabled for bug reports
   and concrete proposals.

Private reporting must be enabled for the security link in the issue chooser
to accept reports. Never redirect sensitive reports to public Issues or Discussions.
See GitHub's [private reporting configuration guide](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/configuring-private-vulnerability-reporting-for-a-repository).

## Merge and branch protection

- Under **Settings > General > Pull Requests**, allow **Squash and merge** and
  disable merge commits and rebase merging. Each accepted PR should produce
  one meaningful commit on `main`.
- Review existing rules under **Settings > Rules > Rulesets** and **Branches**.
  Protect `main` against deletion and force pushes, and require PRs for external
  changes. Avoid overlapping or contradictory protection rules.
- Require successful checks from the existing
  [R-CMD-check workflow](workflows/R-CMD-check.yaml): the six OS/R matrix jobs,
  `CRAN incoming (R-devel, built tarball)`, `SQL integration (DBI + SQLite)`,
  both `PTY integration` jobs, and `Windows input regressions`. Require the
  [pkgdown](workflows/pkgdown.yaml) build for documentation validation as well.
  Select the exact check names displayed on a recent PR; do not guess their
  workflow prefixes. All these workflows run on ordinary PRs to `main`.
- Do not require `worker-probe` or `pre-rc-targeted-diagnostics`: they run on
  demand or special branches and would leave ordinary PRs waiting forever.
- Require one maintainer approval for external PRs. Give the sole maintainer
  an explicit bypass for their own PRs (for example, the repository administrator
  role with a ruleset bypass limited to pull requests). GitHub does not allow
  authors to approve their own PRs. Verify this path works before enforcing the
  rule; avoid requiring approval of the latest push by another person.
  Use the bypass only to satisfy the unavailable second-person review on the
  maintainer's own PRs, after checking the diff and successful CI.
- Keep write access limited to the maintainer; contributing does not confer
  merge permissions. External PRs need the maintainer's review and acceptance.

See GitHub's [ruleset reference](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).
Do not introduce new Actions for labels or routine governance.

## Labels

Preserve all existing unrelated labels, including `accessibility`, `duplicate`,
`invalid`, `question`, and `wontfix`. Keep the existing five definitions unchanged
and add only the three missing labels:

| Label | Color (hex) | Description | Observed state |
| --- | --- | --- | --- |
| `bug` | `d73a4a` | Something isn't working | Exists; preserve |
| `enhancement` | `a2eeef` | New feature or request | Exists; preserve |
| `documentation` | `0075ca` | Improvements or additions to documentation | Exists; preserve |
| `good first issue` | `7057ff` | Good for newcomers | Exists; preserve |
| `help wanted` | `008672` | Extra attention is needed | Exists; preserve |
| `needs reproduction` | `d4c5f9` | More information or a reproducible example is needed | Create |
| `needs discussion` | `fbca04` | Maintainer discussion is needed before implementation | Create |
| `breaking change` | `b60205` | Incompatible change requiring prior discussion and release planning | Create |

The bug and feature forms automatically apply `bug` and `enhancement`,
respectively. All other labels are assigned manually. GitHub requires form
labels to exist; both automatic labels were confirmed present.

The following commands are proposals for an authorized administrator to run,
not automation. GitHub CLI is optional; the labels UI can make the same changes.
First inspect current labels:

```sh
gh label list --repo menshikovs/termr --limit 100
```

Create the three missing labels if they are still absent:

```sh
gh label create "needs reproduction" --repo menshikovs/termr --color d4c5f9 --description "More information or a reproducible example is needed"
gh label create "needs discussion" --repo menshikovs/termr --color fbca04 --description "Maintainer discussion is needed before implementation"
gh label create "breaking change" --repo menshikovs/termr --color b60205 --description "Incompatible change requiring prior discussion and release planning"
```

No command uses `--force` or deletes existing labels. See the
[GitHub CLI label reference](https://cli.github.com/manual/gh_label_create).

After these files reach `main`, preview the issue chooser and both forms,
confirm automatic labels on a legitimate report, and confirm that PRs pick up
the template. Local validation cannot exercise GitHub's hosted form renderer.
