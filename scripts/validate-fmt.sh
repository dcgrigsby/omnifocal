#!/bin/sh
set -e

# KILROY_VALIDATE_FAILURE trap
trap 'echo "KILROY_VALIDATE_FAILURE: validate-fmt.sh failed" >&2' EXIT

echo "=== validate-fmt: checking Go source formatting ==="

UNFORMATTED=$(gofmt -l cmd/omnifocal-server/)

if [ -n "$UNFORMATTED" ]; then
  echo "FAIL: The following files are not formatted:" >&2
  echo "$UNFORMATTED" >&2
  exit 1
fi

echo "PASS: All Go source files are properly formatted."

# Clear the trap on success
trap - EXIT
