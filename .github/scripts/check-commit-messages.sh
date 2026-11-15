#!/usr/bin/env bash
# check-commit-messages: enforces the commit policy (CLAUDE.md) on every
# commit a pull request adds. Run by the commit-messages job in
# .github/workflows/pr-checks.yml; also runnable locally:
#   bash .github/scripts/check-commit-messages.sh origin/dev
#
# For each non-merge commit in BASE_REF..HEAD:
#   - the subject must be a Conventional Commit: type, optional (scope),
#     optional "!", then ": " and a description;
#   - the body and trailers must carry no AI or co-author attribution
#     (co-authored-by:, co-written-by:, "generated with", "on behalf of", or a
#     robot emoji), because no commit in this project may be attributed to a
#     tool or a second author.
# Merge commits are skipped: GitHub writes their messages, not the author.
#
# Kept identical in obiudo-core, obiudo-processor and obiudo-proto.
#
# Argument: BASE_REF (default origin/dev), the branch the PR merges into.
# Exit codes: 0 every commit passes, 1 a commit breaks the policy or the base
# ref is missing.
set -euo pipefail

BASE_REF="${1:-origin/dev}"

SUBJECT_RE='^(feat|fix|refactor|docs|test|chore|build|ci|perf|style|revert)(\([a-z0-9._-]+\))?!?: .+'
ATTRIBUTION_RE='co-authored-by:|co-written-by:|generated with|on behalf of'
# The robot face emoji (U+1F916) as UTF-8 bytes, matched byte for byte.
ROBOT=$'\xf0\x9f\xa4\x96'

# annotate MESSAGE prints a GitHub Actions error annotation. A "%" is escaped
# so text taken from a commit cannot alter the annotation.
annotate() {
  echo "::error title=commit policy::${1//%/%25}"
}

# check_commit SHA prints an annotation for each rule the commit breaks and
# succeeds only if it breaks none.
check_commit() {
  local sha="$1" short subject body ok=0
  short="${sha:0:12}"
  subject="$(git log -1 --format=%s "$sha")"
  body="$(git log -1 --format=%b "$sha")"

  if ! grep -qE "$SUBJECT_RE" <<<"$subject"; then
    annotate "${short}: subject is not a Conventional Commit (type(scope)!: description, types feat fix refactor docs test chore build ci perf style revert): \"${subject}\""
    ok=1
  fi
  if grep -qiE "$ATTRIBUTION_RE" <<<"$body" || LC_ALL=C grep -qF "$ROBOT" <<<"$body"; then
    annotate "${short}: message carries AI or co-author attribution (co-authored-by, co-written-by, \"generated with\", \"on behalf of\" or a robot emoji). Remove it and rewrite the commit."
    ok=1
  fi
  return "$ok"
}

main() {
  if ! git rev-parse --verify --quiet "${BASE_REF}^{commit}" >/dev/null; then
    annotate "Base ref ${BASE_REF} not found. Fetch it first (the workflow checks out with fetch-depth: 0)."
    exit 1
  fi

  local sha checked=0 failed=0
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    checked=$((checked + 1))
    check_commit "$sha" || failed=$((failed + 1))
  done < <(git rev-list --no-merges "${BASE_REF}..HEAD")

  if [ "$failed" -gt 0 ]; then
    echo "commit policy: ${failed} of ${checked} commit(s) in ${BASE_REF}..HEAD break the policy."
    exit 1
  fi
  echo "commit policy: all ${checked} commit(s) in ${BASE_REF}..HEAD pass."
}

main "$@"
