# Security policy

## Reporting a vulnerability

Report suspected vulnerabilities through
[GitHub Private Vulnerability Reporting](https://github.com/menshikovs/termr/security/advisories/new).
Do not report vulnerabilities in public Issues or Discussions, or include
sensitive exploit details in public pull requests.

Private reporting was verified as **disabled on 2026-10-21**. The maintainer
must enable it under repository **Settings > Advanced Security > Private
vulnerability reporting** before this channel can accept reports; see the
[setup checklist](.github/COMMUNITY_SETUP.md). If the form is unavailable,
withhold sensitive details until private reporting is enabled. There is no
alternative email security reporting channel.

Include affected termr and R versions, OS and terminal details where relevant,
the potential impact, and safe reproduction steps or a minimal proof of concept.
Remove credentials, personal data, and unrelated sensitive information.

## What to report

Potential security concerns can involve:

- Unintended subprocess execution or unsafe handling of process arguments.
- Terminal escape sequences that allow untrusted content to trigger unsafe effects.
- Untrusted user input crossing an execution or trust boundary.
- Unintended disclosure through logs, worker data, snapshots, or terminal output.
- SQL integrations, including unsafe query construction or exposed credentials.
- Dependency vulnerabilities that affect termr's use of a package.

These are examples of reportable concerns, not claims of known vulnerabilities.
Ordinary functional bugs belong in Issues when they contain no security-sensitive
information.

## Supported versions

Security maintenance prioritizes the latest stable release. Older versions may
receive fixes at the maintainer's discretion; multiple release branches are not
promised. API stability classifications in [docs/stability.md](docs/stability.md)
describe compatibility and are separate from security reporting: concerns in
stable, experimental, and internal code can all be reported privately.

## Coordinated disclosure

The maintainer will assess reports, coordinate reproduction and fixes with the
reporter, and arrange an advisory or release notes when appropriate. Please
coordinate public disclosure so affected users have an opportunity to update.
There are no guaranteed response or remediation deadlines, dedicated security
staff, or promised rewards or bug bounties.
