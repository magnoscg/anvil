# Security policy

Anvil writes project files and can install AI-tool packs, so filesystem safety
and content provenance are treated as security boundaries.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability or for accidentally
published sensitive information. Report it privately through GitHub's
**Security → Report a vulnerability** flow. If that flow is unavailable, email
[soporte@ogamlabs.com](mailto:soporte@ogamlabs.com) with:

- the affected command and version;
- the smallest safe reproduction;
- the filesystem or provenance impact;
- whether existing user content can be modified or removed.

Do not include live credentials, private repositories or personal data. You can
expect an acknowledgement within five working days. A fix, disclosure date and
release plan will be coordinated according to severity.

## Supported versions

Security fixes target the latest published release. Older releases may receive
an upgrade recommendation instead of a backport. Until a fix is published,
avoid running an affected command against irreplaceable projects and keep normal
version-control or filesystem backups.

## Public security invariants

- A destination that already exists is never overwritten by project generation.
- Tools-only installation preflights every collision before writing.
- Rollback removes only files and directories created by that operation.
- `settings.json` is validated, merged with existing values taking precedence,
  and replaced atomically without following symbolic links.
- Distributed third-party content is pinned and documented in
  `templates/ai-packs/PROVENANCE.yml` and `THIRD_PARTY_NOTICES.md`.

