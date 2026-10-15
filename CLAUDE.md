# obiudo-proto: Claude Working Rules

Always-loaded entrypoint for every task in this repo. It holds the rules that must never be broken, and it's kept short so it is never truncated.

This repo is the **gRPC contract** between `obiudo-core` (NestJS, the book of record) and `obiudo-processor` (Go, moves money). Both services are built against it, so a careless change here can make them disagree about money. Treat every edit as a change to a published API: **additive, reviewed, released.**

---

## Read first

- `README.md`: layout, `make` targets, release rules.
- `proto/obiudo/execution/v1/execution.proto`: the contract itself.
- How the consumers use it: the processor's `docs/ObiudoProcessorEngineering.md` §3 (`../processor`), and Core's `src/app/processor/` (`../core`).

---

## How to work here

1. Branch from **`dev`** (see *Branching* below). `main` is protected: PR only, owner review, required CI. **Never push to `main` or `dev`.**
2. Edit the `.proto`, then `make format` → `make generate` → `make check`. Every command runs in the Docker toolchain, so only Docker is required.
3. Commit the `.proto` change **and** the regenerated `gen/` (plus `go.mod`/`go.sum` if changed) **in the same commit.**
4. Releasing is the owner's job. Never create, move, delete or push tags: give the owner the exact command (`git tag vX.Y.Z && git push origin vX.Y.Z`) to run from an up-to-date `main`, after `dev` has been merged into it.
5. After a release, consumers upgrade in their own repos: the processor runs `go get github.com/obiudo-technology/Proto@vX.Y.Z`, and Core changes its `package.json` `#vX.Y.Z`. If the semantics changed, update the processor engineering doc §3 in the same piece of work.

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
- Package `obiudo.<area>.v<N>` lives in `proto/obiudo/<area>/v<N>/`. A truly breaking redesign is a new `v<N+1>` package alongside the old one, never an edit.

### Tooling is pinned, and changes together
- Never install or upgrade buf or the generators ad hoc.
- A version bump changes, in one commit: the `Dockerfile` ARGs (`BUF_VERSION`, `GO_VERSION`), `version:` in `.github/workflows/ci.yml`, and `go.mod` (`go` line, tool and runtime versions). Then regenerate and commit `gen/`.
- The toolchain container runs with `--network none`. If a command needs the network, the image is missing something: fix the `Dockerfile`, don't remove the flag.

### Security
- No secrets, tokens or real account data anywhere in this repo, including examples and comments.
- Workflows: every action is pinned to a full commit SHA (with a version comment), `permissions: contents: read` unless a job truly needs more, and **never** `pull_request_target`.
- `.github/rulesets/*.json` mirror the rulesets configured on GitHub. Editing a file does **not** change GitHub: tell the owner to re-import it (Settings → Rules → Rulesets).
- Never read or edit any `.env` file.

---

## Branching: `main` + `dev` only (never break this)

The repo has exactly two long-lived branches: **`main`** (released) and **`dev`** (integration). Every other branch is short-lived.

- **Always branch from `dev`:** `git checkout dev && git pull --ff-only && git checkout -b <type>/<short-name>` (`feat/`, `fix/`, `chore/`, `docs/`, `ci/`). Never branch from `main` or from another feature branch.
- **Feature PRs target `dev`** (squash merge is fine there).
- **Only `dev` is PR'd into `main`**, and always with **"Create a merge commit"**, never squash: a squash makes `dev` and `main` diverge, so the next `dev` → `main` PR re-shows old work or conflicts.
- Never push directly to `main` or `dev`; changes arrive by pull request only. Merge a PR only when CI is green and it is up to date with its base.
- Delete a feature branch (local and origin) once it is merged.
- Claude commits locally only: the owner pushes, opens and merges PRs, and creates tags. Give the owner the exact commands.
- Conventional commit messages (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`). **No `Co-Authored-By` trailer.**

**Proto-specific (enforced on GitHub):** the `main` ruleset (`.github/rulesets/main-branch.json`) accepts **merge commits only** and requires the `source-is-dev` check (`.github/workflows/main-source.yml`), so only this repo's `dev` can be merged into `main`. The `dev` ruleset (`dev-branch.json`) blocks direct pushes, force-pushes and deletion of `dev` and requires `buf` and `generated-code`. After a `dev` → `main` merge, the next `dev` → `main` PR will show "out of date": use **Update branch** (the rulesets require an up-to-date head). Editing these files does not change GitHub: the owner re-imports them (Settings → Rules → Rulesets).

---

## Versioning (pre-1.0)

| Change | Bump |
|---|---|
| New field, enum value, message or RPC | minor (`v0.X.0`) |
| Comments, tooling, CI only | patch (`v0.X.Y`) |
| Anything `buf breaking` flags | not allowed. Only with explicit owner approval, which, until 1.0, is a minor bump with the break called out in the release notes |
