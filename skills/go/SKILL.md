---
name: go
description: Go conventions and verification steps. Use when writing, reviewing or debugging Go code.
---

# Go

## Before writing
- Read `go.mod` for the Go version and module path; don't use features newer than that version.
- Match existing patterns for errors, logging (`slog`, zap, klog…) and config before introducing new ones.

## Conventions
- Wrap errors with context: `fmt.Errorf("load config %q: %w", path, err)`. Compare with `errors.Is` / `errors.As`, never by string.
- `context.Context` is the first parameter of anything that does I/O or can block; never store it in a struct.
- Accept interfaces, return concrete types. Define interfaces where they're consumed, keep them small.
- Every goroutine has a clear owner and exit path (context cancel, closed channel, `errgroup`). No fire-and-forget.
- Guard shared state with a mutex or confine it to one goroutine; don't mix both for the same data.
- Table-driven tests with `t.Run`; use `t.Helper()` in helpers and `t.Cleanup()` over `defer` in tests.
- Kubernetes controllers: reconcile must be idempotent; requeue on transient errors, don't loop inside Reconcile.

## Verify (run what the repo supports)
```bash
gofmt -l . && go vet ./...
go build ./...
go test -race -count=1 ./path/to/changed/...
golangci-lint run ./...   # if .golangci.yml exists
```
Run the narrowest package set first; only run `./...` before finishing.
