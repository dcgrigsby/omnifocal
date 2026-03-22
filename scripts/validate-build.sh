#!/bin/sh
set -e

# KILROY_VALIDATE_FAILURE trap
trap 'echo "KILROY_VALIDATE_FAILURE: validate-build.sh failed" >&2' EXIT

echo "=== validate-build: building omnifocal-server binary ==="

go build -o omnifocal-server ./cmd/omnifocal-server/

if [ ! -f omnifocal-server ]; then
  echo "FAIL: binary omnifocal-server was not produced" >&2
  exit 1
fi

echo "PASS: omnifocal-server binary built successfully."
ls -la omnifocal-server

# Clear the trap on success
trap - EXIT
