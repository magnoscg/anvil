.PHONY: build test test-integration install clean lint fmt all

VERSION ?= dev
BINARY_NAME := anvil
BUILD_DIR := bin
LDFLAGS := -ldflags "-X main.Version=$(VERSION)"

## build: Compile the binary with version info
build:
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/anvil

## test: Run unit tests
test:
	go test ./...

## test-integration: Run integration tests (requires macOS + Xcode)
test-integration:
	go test -tags integration -v -count=1 ./...

## install: Install binary to GOPATH/bin
install:
	go install $(LDFLAGS) ./cmd/anvil

## clean: Remove build artifacts and test caches
clean:
	rm -rf $(BUILD_DIR)
	go clean -testcache

## lint: Run golangci-lint (if available)
lint:
	@which golangci-lint > /dev/null 2>&1 && golangci-lint run ./... || echo "golangci-lint not installed, skipping (install: https://golangci-lint.run/welcome/install/)"

## fmt: Format all Go source files
fmt:
	gofmt -w .

## all: Format, lint, test, and build
all: fmt lint test build
