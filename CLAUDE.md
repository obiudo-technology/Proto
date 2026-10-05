# settlementOne-proto: Claude Working Rules

Always-loaded entrypoint for every task in this repo. It holds the rules that must never be broken, and it's kept short so it is never truncated.

This repo is the **gRPC contract** between `settlementOne-core` (NestJS, the book of record) and `settlementOne-processor` (Go, moves money). Both services are built against it, so a careless change here can make them disagree about money. Treat every edit as a change to a published API: **additive, reviewed, released.**

---

## Read first

- `README.md`: layout, `make` targets, release rules.
- `proto/settlementone/execution/v1/execution.proto`: the contract itself.
- How the consumers use it: the processor's `docs/SettlementOneProcessorEngineering.md` §3 (`../processor`), and Core's `src/app/processor/` (`../core`).

---

## How to work here

1. Branch from `main`. `main` is protected: PR only, owner review, required CI, squash merge. **Never push to `main`.**
2. Edit the `.proto`, then `make format` → `make generate` → `make check`. Every command runs in the Docker toolchain, so only Docker is required.
3. Commit the `.proto` change **and** the regenerated `gen/` (plus `go.mod`/`go.sum` if changed) **in the same commit.**
4. Releasing is the owner's job. Never create, move, delete or push tags: give the owner the exact command (`git tag vX.Y.Z && git push origin vX.Y.Z`) to run from an up-to-date `main`.
5. After a release, consumers upgrade in their own repos: the processor runs `go get github.com/settlement-one/Proto@vX.Y.Z`, and Core changes its `package.json` `#vX.Y.Z`. If the semantics changed, update the processor engineering doc §3 in the same piece of work.

---

## Hard rules (never break these)

### Contract changes are additive only
- **Never** renumber, reuse, rename or remove a field, enum value, message, RPC or service, and never change a field's type or `oneof` membership.
- To retire something: mark it `[deprecated = true]`, and when it's finally removed, `reserved` both its number and its name.
- `buf breaking` (FILE level) must pass. The `buf skip breaking` PR label is used **only** with the owner's explicit approval for that PR, with the reason stated in the PR description.

### Generated code is never hand-edited
- `gen/` is output. Change the `.proto` and run `make generate`. CI fails if `gen/` differs from what the `.proto` produces.

### Money
- Amounts are `int64` **minor units**. **Never** `float`/`double` for money, and never money inside `google.protobuf.Struct` (its numbers are doubles).

### Every element is documented
- Every service, RPC, message, enum value and every non-obvious field gets a `//` comment. These become the Go doc comments consumers read.
- State the semantics a caller relies on: retry safety, units, when a field is empty. Comment additions alone are a patch release.

### Naming and style (enforced by `buf lint` STANDARD)
- Enum zero value is `<ENUM>_UNSPECIFIED = 0`, and values are prefixed with the enum name. RPCs use `<Rpc>Request`/`<Rpc>Response`.
- Package `settlementone.<area>.v<N>` lives in `proto/settlementone/<area>/v<N>/`. A truly breaking redesign is a new `v<N+1>` package alongside the old one, never an edit.

### Tooling is pinned, and changes together
- Never install or upgrade buf or the generators ad hoc.
- A version bump changes, in one commit: the `Dockerfile` ARGs (`BUF_VERSION`, `GO_VERSION`), `version:` in `.github/workflows/ci.yml`, and `go.mod` (`go` line, tool and runtime versions). Then regenerate and commit `gen/`.
- The toolchain container runs with `--network none`. If a command needs the network, the image is missing something: fix the `Dockerfile`, don't remove the flag.

### Security
- No secrets, tokens or real account data anywhere in this repo, including examples and comments.
- Workflows: every action is pinned to a full commit SHA (with a version comment), `permissions: contents: read` unless a job truly needs more, and **never** `pull_request_target`.
- `.github/rulesets/*.json` mirror the rulesets configured on GitHub. Editing a file does **not** change GitHub: tell the owner to re-import it (Settings → Rules → Rulesets).
- Never read or edit any `.env` file.

### Git
- Clear conventional commit messages (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`). **No `Co-Authored-By` trailer.**
- Never `git push` or push tags yourself: give the owner the command.

---

## Versioning (pre-1.0)

| Change | Bump |
|---|---|
| New field, enum value, message or RPC | minor (`v0.X.0`) |
| Comments, tooling, CI only | patch (`v0.X.Y`) |
| Anything `buf breaking` flags | not allowed. Only with explicit owner approval, which, until 1.0, is a minor bump with the break called out in the release notes |
