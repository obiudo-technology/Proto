#!/usr/bin/env bash
# check-pr-description: a pull request's description must follow this repo's
# .github/pull_request_template.md. Run by .github/workflows/pr-description.yml
# on every pull request, to any branch, and again whenever the description
# is edited.
#
# Rules:
#   - not empty;
#   - every "## " heading of the template is present, word for word (write
#     "None" or "Not touched" under one rather than deleting it);
#   - the template's guidance comments (<!-- ... -->) are removed;
#   - no AI or tool attribution (CLAUDE.md, "No AI attribution, ever").
#
# Kept identical in obiudo-core, obiudo-processor and obiudo-proto; the
# headings come from each repo's own template.
#
# Inputs (env): PR_BODY (the description), TEMPLATE (default
# .github/pull_request_template.md).
# Exit codes: 0 follows the template, 1 doesn't.
set -euo pipefail

TEMPLATE="${TEMPLATE:-.github/pull_request_template.md}"
# GitHub stores descriptions with Windows line endings.
BODY="$(printf '%s' "${PR_BODY:-}" | tr -d '\r')"
# Narrower than the commit check's "generated with": a description may say
# "a migration generated with make db-generate".
ATTRIBUTION_RE='co-authored-by:|co-written-by:|generated with \[?(claude|chatgpt|copilot|cursor|gemini)|on behalf of (claude|an ai)'
# The robot face emoji (U+1F916) as UTF-8 bytes, matched byte for byte.
ROBOT=$'\xf0\x9f\xa4\x96'

failed=0

# fail MESSAGE prints a GitHub Actions error annotation (plain text elsewhere)
# and marks the check as failed.
fail() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1"; else echo "error: $1"; fi
  failed=1
}

if [ ! -f "$TEMPLATE" ]; then
  fail "$TEMPLATE is missing, so there is nothing to check the description against."
  exit 1
fi

if [ -z "${BODY//[[:space:]]/}" ]; then
  fail "The description is empty. Start from $TEMPLATE (GitHub pre-fills it) and fill in every section."
  exit 1
fi

while IFS= read -r heading; do
  if ! grep -qxF -- "$heading" <<<"$BODY"; then
    fail "Missing the heading \"$heading\" from $TEMPLATE. Keep every heading; write \"None\" or \"Not touched\" under it instead of deleting it."
  fi
done < <(grep -E '^## ' "$TEMPLATE" | tr -d '\r')

if grep -qF -- '<!--' <<<"$BODY"; then
  fail "The template's guidance comments (<!-- ... -->) are still in the description. Remove them."
fi

if grep -qiE -- "$ATTRIBUTION_RE" <<<"$BODY" || LC_ALL=C grep -qF -- "$ROBOT" <<<"$BODY"; then
  fail "The description carries AI or tool attribution. Remove it (CLAUDE.md: no AI attribution, ever)."
fi

if [ "$failed" -eq 0 ]; then
  echo "The description follows $TEMPLATE."
fi
exit "$failed"
