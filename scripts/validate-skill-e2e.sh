#!/bin/sh
set -e

# --- Configuration ---
RUN_ID="${KILROY_RUN_ID:-01KM92J67JA36AA5PWJYNEVBRV}"
EVIDENCE_ROOT=".ai/runs/${RUN_ID}/test-evidence/latest"
SERVER_PID=""
PORT=7890
TEMP_DIR=""
REPO_ROOT="$(pwd)"

# --- Trap: kill server, clean up temp dir, report failure ---
cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Cleaning up: killing server PID $SERVER_PID"
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    echo "Cleaning up: removing temp dir $TEMP_DIR"
    rm -rf "$TEMP_DIR"
  fi
}

trap 'cleanup; echo "KILROY_VALIDATE_FAILURE: validate-skill-e2e.sh failed" >&2' EXIT

echo "=== validate-skill-e2e: IT-7 End-to-End Skill Validation ==="

# --- Setup evidence directories ---
mkdir -p "${EVIDENCE_ROOT}/IT-7"

ALL_PASS=true

# ========================================
# Step 1: Build server
# ========================================
echo ""
echo "--- Step 1: Build server ---"
go build -o omnifocal-server ./cmd/omnifocal-server/ 2>&1 | tee "${EVIDENCE_ROOT}/IT-7/build.log"
if [ ! -f omnifocal-server ]; then
  echo "FAIL: Server binary not built" >&2
  ALL_PASS=false
fi

# ========================================
# Step 2: Start server
# ========================================
echo ""
echo "--- Step 2: Start server ---"
./omnifocal-server > "${EVIDENCE_ROOT}/IT-7/server.log" 2>&1 &
SERVER_PID=$!
echo "Server started with PID $SERVER_PID"

# Wait for server ready
echo "Waiting for server to be ready..."
READY=false
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -s -o /dev/null -w '' "http://localhost:${PORT}/health" 2>/dev/null; then
    READY=true
    echo "Server is ready (attempt $i)"
    break
  fi
  sleep 0.5
done

if [ "$READY" != "true" ]; then
  echo "FAIL: Server did not become ready within 5 seconds" >&2
  ALL_PASS=false
fi

# ========================================
# Step 3: Create temp workspace with skill
# ========================================
echo ""
echo "--- Step 3: Create temp workspace ---"
TEMP_DIR=$(mktemp -d /tmp/omnifocal-test-XXXXXX)
mkdir -p "${TEMP_DIR}/.claude/skills/omnifocal/"
cp skills/omnifocal/SKILL.md "${TEMP_DIR}/.claude/skills/omnifocal/SKILL.md"
echo "Skill installed to ${TEMP_DIR}/.claude/skills/omnifocal/SKILL.md"

# ========================================
# Step 4: Run Claude Code CLI
# ========================================
echo ""
echo "--- Step 4: Run Claude Code CLI ---"

# Check if claude CLI is available
if ! command -v claude >/dev/null 2>&1; then
  echo "FAIL: claude CLI not found on PATH" >&2
  echo "claude CLI not available" > "${EVIDENCE_ROOT}/IT-7/claude_output.txt"
  ALL_PASS=false
else
  CLAUDE_PROMPT="Use the omnifocal skill to list my OmniFocus inbox tasks. Send a curl POST request to http://localhost:7890/eval with a JavaScript query that gets inbox tasks and returns them as JSON using JSON.stringify. Return the raw JSON result from the server."

  echo "Running: cd ${TEMP_DIR} && claude -p '...' --allowedTools 'Bash(curl:*)' --max-turns 5"

  cd "${TEMP_DIR}"
  CLAUDE_OUTPUT=$(claude -p "$CLAUDE_PROMPT" \
    --allowedTools 'Bash(curl:*)' \
    --max-turns 5 \
    2>&1) || true
  cd "$REPO_ROOT"

  echo "$CLAUDE_OUTPUT" > "${EVIDENCE_ROOT}/IT-7/claude_output.txt"
  echo "Claude output (first 1000 chars):"
  echo "$CLAUDE_OUTPUT" | head -c 1000
  echo ""
fi

# ========================================
# Step 5: Verify output contains real data
# ========================================
echo ""
echo "--- Step 5: Verify output ---"

if [ -f "${EVIDENCE_ROOT}/IT-7/claude_output.txt" ] && [ -s "${EVIDENCE_ROOT}/IT-7/claude_output.txt" ]; then
  # Check for JSON with recognizable OmniFocus fields
  if grep -q '"name"' "${EVIDENCE_ROOT}/IT-7/claude_output.txt"; then
    echo "IT-7: PASS - Output contains JSON with 'name' field"
  elif grep -q 'name' "${EVIDENCE_ROOT}/IT-7/claude_output.txt" && grep -q 'task\|project\|inbox\|OmniFocus' "${EVIDENCE_ROOT}/IT-7/claude_output.txt"; then
    echo "IT-7: PASS - Output contains OmniFocus data references"
  else
    echo "IT-7: FAIL - Output does not contain recognizable OmniFocus data" >&2
    echo "Full output:"
    cat "${EVIDENCE_ROOT}/IT-7/claude_output.txt"
    ALL_PASS=false
  fi
else
  echo "IT-7: FAIL - claude_output.txt is empty or missing" >&2
  ALL_PASS=false
fi

# ========================================
# Write manifest fragment
# ========================================
echo ""
echo "=== Writing IT-7 manifest fragment ==="

cat > "${EVIDENCE_ROOT}/IT-7/manifest_fragment.json" <<MANIFEST_EOF
{
  "IT-7": {
    "status": "$([ "$ALL_PASS" = "true" ] && echo "pass" || echo "fail")",
    "artifacts": [
      "IT-7/claude_output.txt",
      "IT-7/server.log"
    ]
  }
}
MANIFEST_EOF

# ========================================
# Self-Verification
# ========================================
echo ""
echo "=== Self-Verification ==="
VERIFY_PASS=true

# claude_output.txt must exist
if [ ! -f "${EVIDENCE_ROOT}/IT-7/claude_output.txt" ]; then
  echo "SELF-VERIFY FAIL: claude_output.txt missing" >&2
  VERIFY_PASS=false
fi

# server.log must exist
if [ ! -f "${EVIDENCE_ROOT}/IT-7/server.log" ]; then
  echo "SELF-VERIFY FAIL: server.log missing" >&2
  VERIFY_PASS=false
fi

echo ""
if [ "$ALL_PASS" != "true" ]; then
  echo "FAIL: IT-7 end-to-end validation failed" >&2
  exit 1
fi

if [ "$VERIFY_PASS" != "true" ]; then
  echo "FAIL: Self-verification failed" >&2
  exit 1
fi

echo "ALL PASS: IT-7 end-to-end validation passed"

# Clear the failure trap, just clean up
trap 'cleanup' EXIT
