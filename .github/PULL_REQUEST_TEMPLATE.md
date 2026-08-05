## What changed

<!-- Describe the user-visible behaviour and why this change is needed. -->

## Verification

- [ ] `go test ./...`
- [ ] `go test -race ./...`
- [ ] `go vet ./...`
- [ ] `go mod verify`
- [ ] `go run golang.org/x/vuln/cmd/govulncheck@v1.6.0 ./...`
- [ ] `./scripts/validate-skill-content.sh`
- [ ] The Example project still builds and its Swift tests pass, when affected

## Safety and provenance

- [ ] Generation still refuses existing destinations and unsafe paths
- [ ] Rollback can remove only resources created by the current operation
- [ ] Bundled third-party content remains pinned in `PROVENANCE.yml` and notices
- [ ] No credential, private path or production configuration is included
