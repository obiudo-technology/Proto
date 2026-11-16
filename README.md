# Obiudo Proto

The gRPC contract between `obiudo-core` (NestJS) and `obiudo-processor` (Go).

- **Sources:**
  - `proto/obiudo/execution/v1/execution.proto`: moving money on payment rails (`ExecutionService`: `Execute`, `GetExecution`, `GetQuote`).
  - `proto/obiudo/collection/v1/collection.proto` (since `v0.5.0`): NGN collection. `CollectionService` (hosted by the processor: `ProvisionAccount`, `ListDeposits`) and `CollectionEventsService` (hosted by Core: `RecordDeposit`).
- **Go:** generated into `gen/go/` and committed. Import `github.com/obiudo-technology/Proto/gen/go/obiudo/execution/v1` (package `executionv1`) and `github.com/obiudo-technology/Proto/gen/go/obiudo/collection/v1` (package `collectionv1`).
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
- Branches: `main` (released) and `dev` (integration) only. Work branches come from `dev` and are PR'd into `dev`; only `dev` is PR'd into `main`. `main` is protected: PR only, from `dev` only (`source-is-dev` check), owner review, CI green, merge commits only. `dev` is protected: PR only, CI green (`buf`, `generated-code`, plus `commit-messages` and `secret-scan` from `pr-checks.yml`: Conventional Commit messages with no AI or co-author attribution, and no secrets in the PR's commits).
