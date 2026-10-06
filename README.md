# Obiudo Proto

The gRPC contract between `obiudo-core` (NestJS) and `obiudo-processor` (Go).

- **Source:** `proto/obiudo/execution/v1/execution.proto`
- **Go:** generated into `gen/go/` and committed. Import `github.com/obiudo-technology/Proto/gen/go/obiudo/execution/v1` (package `executionv1`).
- **TypeScript (Core):** loads the `.proto` at runtime. Install with `"obiudo-proto": "github:obiudo-technology/Proto#<tag>"`.

## Working on the contract

Only Docker is needed. Every command runs in a pinned toolchain container (buf + Go + generators, see `Dockerfile`):

```sh
make generate   # regenerate gen/go after editing a .proto; commit the result
make check      # lint, format, breaking-change check, generate, build (what CI runs)
make format     # auto-format .proto files
make shell      # shell inside the toolchain container
```

## Rules

- Changes are **additive only**. Never renumber, rename or remove a field, enum value or RPC. Deprecate instead. `buf breaking` enforces this in CI.
- Every release is a semver tag (`vX.Y.Z`) cut from `main`. Consumers pin tags, so a tag is never moved or deleted.
- `main` is protected: PR only, owner review, CI green, squash merge.
