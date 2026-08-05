# Contributing to Anvil

Thank you for helping improve Anvil. Keep changes small, reviewable and covered
by tests. Filesystem behaviour and bundled content need extra care because Anvil
runs inside other people's projects.

## Branches

Development follows Gitflow:

- branch `feature/*` from `develop` and open the pull request back to `develop`;
- use `release/*` to prepare a semantic `X.Y.Z` release;
- reserve `hotfix/*` for urgent fixes branched from `main`;
- do not force-push shared `main` or `develop` branches.

## Local verification

Run the checks relevant to every change:

```text
go test ./...
go test -race ./...
go vet ./...
go mod verify
go run golang.org/x/vuln/cmd/govulncheck@v1.6.0 ./...
./scripts/validate-skill-content.sh
```

Changes to the generated iOS project must also build and test the
`Arquitectura-Dev` scheme in `Example/Arquitectura.xcodeproj`.

## Generator changes

Add tests for empty destinations, existing files and directories, symbolic
links, path traversal, injected write failures and rollback ownership. A new
write path must participate in plan, preflight and apply; it must not bypass the
transaction.

## Bundled content

New or modified skills need original or precisely traceable content, complete
front matter, a compatible licence and an updated
`templates/ai-packs/PROVENANCE.yml`. Add required notices to
`THIRD_PARTY_NOTICES.md` and run the content validator before opening a pull
request.

For vulnerabilities or sensitive disclosures, follow [SECURITY.md](SECURITY.md)
instead of opening a public issue.
