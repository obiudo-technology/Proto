<!--
How to fill this in
- Write for the reviewer: someone who knows the contract but has not seen
  this change.
- Plain English, short sentences, bullets over paragraphs. No em dash
  characters (CLAUDE.md, writing style).
- Keep every heading. Write "None" or "Not touched" rather than deleting a
  section. The pr-description check fails a PR that drops a heading or keeps
  these comments.
- Name messages, fields and RPCs exactly as they are in the .proto.
- Delete these comments before you submit.
-->

## Summary

<!-- 2 to 4 sentences: what the contract change is, why, and which side
(Core, the processor) needs it. Link the plan or the PR it serves. -->

## What changes

<!-- One bullet per service, RPC, message, field or enum value added or
deprecated, with its field number and meaning. -->

-

## Compatibility

<!-- Changes are additive only (never renumber, rename, retype or remove;
deprecate instead). Confirm `buf breaking` passes, or explain the owner's
approval for a `buf skip breaking` label. Say what an old client or server
does with the new fields. -->

-

## Release

<!-- The tag this becomes (semver: patch for comments, minor for additions)
and what each consumer must do: Core bumps "obiudo-proto" in package.json,
the processor runs `make proto-bump V=vX.Y.Z`. "None" for a change that
isn't released yet. -->

-

## How it was tested

- [ ] `make check` is green (buf lint, format, breaking, generate, build)
- [ ] `gen/` regenerated with `make generate` and committed
- Consumers built against it (a local `go.work` or a Core install from the branch), or "Not run" and why:
  -

## Reviewer notes

<!-- Where to look first, naming or numbering decisions, and anything a
consumer must watch for. -->

-
