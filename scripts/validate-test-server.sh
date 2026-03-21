#!/bin/sh
set -e

# --- Configuration ---
RUN_ID="${KILROY_RUN_ID:-01KM92J67JA36AA5PWJYNEVBRV}"
EVIDENCE_ROOT=".ai/runs/${RUN_ID}/test-evidence/latest"
SERVER_PID=""
PORT=7890

# --- Trap: kill server and report failure ---
cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Cleaning up: killing server PID $SERVER_PID"
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}

trap 'cleanup; echo "KILROY_VALIDATE_FAILURE: validate-test-server.sh failed" >&2' EXIT

echo "=== validate-test-server: integration tests IT-1 through IT-5 ==="

# --- Setup evidence directories ---
mkdir -p "${EVIDENCE_ROOT}/IT-1"
mkdir -p "${EVIDENCE_ROOT}/IT-2"
mkdir -p "${EVIDENCE_ROOT}/IT-3"
mkdir -p "${EVIDENCE_ROOT}/IT-4"
mkdir -p "${EVIDENCE_ROOT}/IT-5"

# Track overall pass/fail
ALL_PASS=true

# --- Build the binary ---
echo ""
echo "--- Building omnifocal-server ---"
{
  echo "Building omnifocal-server..."
  go build -o omnifocal-server ./cmd/omnifocal-server/ 2>&1
  BUILD_EXIT=$?
  if [ $BUILD_EXIT -eq 0 ] && [ -f omnifocal-server ]; then
    echo "Build succeeded (exit $BUILD_EXIT)"
    ls -la omnifocal-server
  else
    echo "FAIL: build failed or binary not produced (exit $BUILD_EXIT)"
    ALL_PASS=false
  fi
} | tee "${EVIDENCE_ROOT}/IT-1/build.log"

# --- Start the server ---
echo ""
echo "--- Starting omnifocal-server on port ${PORT} ---"
./omnifocal-server &
SERVER_PID=$!
echo "Server started with PID $SERVER_PID"

# --- Wait for server ready ---
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
# IT-1: Server Build and Start
# ========================================
echo ""
echo "=== IT-1: Server Build and Start ==="
IT1_PASS=true

HEALTH_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}/health" 2>/dev/null || echo "000")
echo "Health check status: ${HEALTH_STATUS}"
echo "${HEALTH_STATUS}" > "${EVIDENCE_ROOT}/IT-1/health_response.txt"

if [ "$HEALTH_STATUS" = "200" ]; then
  echo "IT-1: PASS - Server built and /health returns 200"
else
  echo "IT-1: FAIL - Expected 200, got ${HEALTH_STATUS}" >&2
  IT1_PASS=false
  ALL_PASS=false
fi

# ========================================
# IT-2: Server /eval Happy Path
# ========================================
echo ""
echo "=== IT-2: Server /eval Happy Path ==="
IT2_PASS=true

# POST valid OmniFocus JS
EVAL_JS='var app = Application("OmniFocus"); var doc = app.defaultDocument; var tasks = doc.flattenedTasks(); JSON.stringify(tasks.slice(0, 5).map(function(t) { return {name: t.name(), id: t.id()}; }))'

EVAL_RESPONSE=$(curl -s -w '\n%{http_code}' -X POST -d "$EVAL_JS" "http://localhost:${PORT}/eval" 2>/dev/null)
EVAL_BODY=$(echo "$EVAL_RESPONSE" | sed '$d')
EVAL_STATUS=$(echo "$EVAL_RESPONSE" | tail -1)

echo "$EVAL_BODY" > "${EVIDENCE_ROOT}/IT-2/response.txt"
echo "$EVAL_STATUS" > "${EVIDENCE_ROOT}/IT-2/http_status.txt"

echo "Eval status: ${EVAL_STATUS}"
echo "Eval body (first 500 chars): $(echo "$EVAL_BODY" | head -c 500)"

if [ "$EVAL_STATUS" = "200" ]; then
  echo "IT-2: HTTP status PASS (200)"
else
  echo "IT-2: FAIL - Expected HTTP 200, got ${EVAL_STATUS}" >&2
  IT2_PASS=false
  ALL_PASS=false
fi

# Check response body contains JSON with "name" field
if echo "$EVAL_BODY" | grep -q '"name"'; then
  echo "IT-2: Content PASS - Response contains 'name' field"
else
  echo "IT-2: FAIL - Response does not contain expected 'name' field" >&2
  IT2_PASS=false
  ALL_PASS=false
fi

# ========================================
# IT-3: Server /eval Error Handling
# ========================================
echo ""
echo "=== IT-3: Server /eval Error Handling ==="
IT3_PASS=true

# 3a: POST invalid JS -> expect 500
ERR_RESPONSE=$(curl -s -w '\n%{http_code}' -X POST -d 'this is not valid javascript syntax %%%' "http://localhost:${PORT}/eval" 2>/dev/null)
ERR_BODY=$(echo "$ERR_RESPONSE" | sed '$d')
ERR_STATUS=$(echo "$ERR_RESPONSE" | tail -1)

echo "$ERR_BODY" > "${EVIDENCE_ROOT}/IT-3/error_500_response.txt"
echo "$ERR_STATUS" > "${EVIDENCE_ROOT}/IT-3/error_500_status.txt"

echo "Error 500 status: ${ERR_STATUS}"
echo "Error 500 body: $(echo "$ERR_BODY" | head -c 500)"

if [ "$ERR_STATUS" = "500" ]; then
  echo "IT-3a: HTTP status PASS (500)"
else
  echo "IT-3a: FAIL - Expected HTTP 500, got ${ERR_STATUS}" >&2
  IT3_PASS=false
  ALL_PASS=false
fi

# Check error text contains error-related content (case-insensitive)
if echo "$ERR_BODY" | grep -qi 'error\|execution\|Error'; then
  echo "IT-3a: Content PASS - Error text present"
else
  echo "IT-3a: FAIL - No error text in 500 response" >&2
  IT3_PASS=false
  ALL_PASS=false
fi

# 3b: POST empty body -> expect 400
EMPTY_RESPONSE=$(curl -s -w '\n%{http_code}' -X POST -d '' "http://localhost:${PORT}/eval" 2>/dev/null)
EMPTY_BODY=$(echo "$EMPTY_RESPONSE" | sed '$d')
EMPTY_STATUS=$(echo "$EMPTY_RESPONSE" | tail -1)

echo "$EMPTY_BODY" > "${EVIDENCE_ROOT}/IT-3/error_400_response.txt"
echo "$EMPTY_STATUS" > "${EVIDENCE_ROOT}/IT-3/error_400_status.txt"

echo "Error 400 status: ${EMPTY_STATUS}"
echo "Error 400 body: ${EMPTY_BODY}"

if [ "$EMPTY_STATUS" = "400" ]; then
  echo "IT-3b: HTTP status PASS (400)"
else
  echo "IT-3b: FAIL - Expected HTTP 400, got ${EMPTY_STATUS}" >&2
  IT3_PASS=false
  ALL_PASS=false
fi

# Check 400 body is non-empty
if [ -n "$EMPTY_BODY" ]; then
  echo "IT-3b: Content PASS - Non-empty 400 response"
else
  echo "IT-3b: FAIL - 400 response body is empty" >&2
  IT3_PASS=false
  ALL_PASS=false
fi

# ========================================
# IT-4: Server Health Check (standalone)
# ========================================
echo ""
echo "=== IT-4: Server Health Check ==="
IT4_PASS=true

HEALTH4_RESPONSE=$(curl -s -w '\n%{http_code}' "http://localhost:${PORT}/health" 2>/dev/null)
HEALTH4_BODY=$(echo "$HEALTH4_RESPONSE" | sed '$d')
HEALTH4_STATUS=$(echo "$HEALTH4_RESPONSE" | tail -1)

echo "${HEALTH4_BODY}" > "${EVIDENCE_ROOT}/IT-4/health_response.txt"
echo "${HEALTH4_STATUS}" >> "${EVIDENCE_ROOT}/IT-4/health_response.txt"

if [ "$HEALTH4_STATUS" = "200" ]; then
  echo "IT-4: PASS - /health returns 200"
else
  echo "IT-4: FAIL - Expected 200, got ${HEALTH4_STATUS}" >&2
  IT4_PASS=false
  ALL_PASS=false
fi

# ========================================
# IT-5: launchd Plist Validation
# ========================================
echo ""
echo "=== IT-5: launchd Plist Validation ==="
IT5_PASS=true

PLUTIL_OUTPUT=$(plutil -lint launchd/com.omnifocal.server.plist 2>&1)
echo "$PLUTIL_OUTPUT" > "${EVIDENCE_ROOT}/IT-5/plutil_output.txt"
echo "plutil result: ${PLUTIL_OUTPUT}"

if echo "$PLUTIL_OUTPUT" | grep -q "OK"; then
  echo "IT-5a: PASS - plutil lint OK"
else
  echo "IT-5a: FAIL - plutil lint did not report OK" >&2
  IT5_PASS=false
  ALL_PASS=false
fi

# Grep for ProgramArguments and KeepAlive
PLIST_CONTENTS=""
PA_LINE=$(grep "ProgramArguments" launchd/com.omnifocal.server.plist 2>/dev/null || true)
KA_LINE=$(grep "KeepAlive" launchd/com.omnifocal.server.plist 2>/dev/null || true)
PLIST_CONTENTS="${PA_LINE}
${KA_LINE}"
echo "$PLIST_CONTENTS" > "${EVIDENCE_ROOT}/IT-5/plist_contents.txt"

if [ -n "$PA_LINE" ]; then
  echo "IT-5b: PASS - ProgramArguments found"
else
  echo "IT-5b: FAIL - ProgramArguments not found" >&2
  IT5_PASS=false
  ALL_PASS=false
fi

if [ -n "$KA_LINE" ]; then
  echo "IT-5c: PASS - KeepAlive found"
else
  echo "IT-5c: FAIL - KeepAlive not found" >&2
  IT5_PASS=false
  ALL_PASS=false
fi

# ========================================
# Write manifest.json
# ========================================
echo ""
echo "=== Writing manifest.json ==="

cat > "${EVIDENCE_ROOT}/manifest.json" <<MANIFEST_EOF
{
  "run_id": "${RUN_ID}",
  "scenarios": {
    "IT-1": {
      "status": "$([ "$IT1_PASS" = "true" ] && echo "pass" || echo "fail")",
      "artifacts": [
        "IT-1/build.log",
        "IT-1/health_response.txt"
      ]
    },
    "IT-2": {
      "status": "$([ "$IT2_PASS" = "true" ] && echo "pass" || echo "fail")",
      "artifacts": [
        "IT-2/response.txt",
        "IT-2/http_status.txt"
      ]
    },
    "IT-3": {
      "status": "$([ "$IT3_PASS" = "true" ] && echo "pass" || echo "fail")",
      "artifacts": [
        "IT-3/error_500_response.txt",
        "IT-3/error_500_status.txt",
        "IT-3/error_400_response.txt",
        "IT-3/error_400_status.txt"
      ]
    },
    "IT-4": {
      "status": "$([ "$IT4_PASS" = "true" ] && echo "pass" || echo "fail")",
      "artifacts": [
        "IT-4/health_response.txt"
      ]
    },
    "IT-5": {
      "status": "$([ "$IT5_PASS" = "true" ] && echo "pass" || echo "fail")",
      "artifacts": [
        "IT-5/plutil_output.txt",
        "IT-5/plist_contents.txt"
      ]
    }
  }
}
MANIFEST_EOF

echo "Manifest written to ${EVIDENCE_ROOT}/manifest.json"

# ========================================
# SELF-VERIFICATION BLOCK
# ========================================
echo ""
echo "=== Self-Verification ==="
VERIFY_PASS=true

# 1. manifest.json exists
if [ ! -f "${EVIDENCE_ROOT}/manifest.json" ]; then
  echo "SELF-VERIFY FAIL: manifest.json does not exist" >&2
  VERIFY_PASS=false
fi

# 2. manifest.json contains all IT-* IDs
for IT_ID in IT-1 IT-2 IT-3 IT-4 IT-5; do
  if ! grep -q "$IT_ID" "${EVIDENCE_ROOT}/manifest.json"; then
    echo "SELF-VERIFY FAIL: manifest.json missing ${IT_ID}" >&2
    VERIFY_PASS=false
  fi
done

# 3. Evidence files exist and are non-empty
for ARTIFACT in \
  "IT-1/build.log" \
  "IT-1/health_response.txt" \
  "IT-2/response.txt" \
  "IT-2/http_status.txt" \
  "IT-3/error_500_response.txt" \
  "IT-3/error_500_status.txt" \
  "IT-3/error_400_response.txt" \
  "IT-3/error_400_status.txt" \
  "IT-4/health_response.txt" \
  "IT-5/plutil_output.txt" \
  "IT-5/plist_contents.txt"; do
  FPATH="${EVIDENCE_ROOT}/${ARTIFACT}"
  if [ ! -f "$FPATH" ]; then
    echo "SELF-VERIFY FAIL: artifact missing: ${ARTIFACT}" >&2
    VERIFY_PASS=false
  elif [ ! -s "$FPATH" ]; then
    echo "SELF-VERIFY FAIL: artifact is empty: ${ARTIFACT}" >&2
    VERIFY_PASS=false
  fi
done

# 4. Content assertions
# IT-2/response.txt must contain JSON with "name" fields
if [ -f "${EVIDENCE_ROOT}/IT-2/response.txt" ]; then
  if ! grep -q '"name"' "${EVIDENCE_ROOT}/IT-2/response.txt"; then
    echo "SELF-VERIFY FAIL: IT-2/response.txt does not contain 'name' field" >&2
    VERIFY_PASS=false
  fi
fi

# IT-3/error_500_response.txt must contain error text
if [ -f "${EVIDENCE_ROOT}/IT-3/error_500_response.txt" ]; then
  if ! grep -qi 'error\|execution' "${EVIDENCE_ROOT}/IT-3/error_500_response.txt"; then
    echo "SELF-VERIFY FAIL: IT-3/error_500_response.txt does not contain error text" >&2
    VERIFY_PASS=false
  fi
fi

# IT-5/plutil_output.txt must contain OK
if [ -f "${EVIDENCE_ROOT}/IT-5/plutil_output.txt" ]; then
  if ! grep -q "OK" "${EVIDENCE_ROOT}/IT-5/plutil_output.txt"; then
    echo "SELF-VERIFY FAIL: IT-5/plutil_output.txt does not contain OK" >&2
    VERIFY_PASS=false
  fi
fi

# IT-5/plist_contents.txt must contain ProgramArguments and KeepAlive
if [ -f "${EVIDENCE_ROOT}/IT-5/plist_contents.txt" ]; then
  if ! grep -q "ProgramArguments" "${EVIDENCE_ROOT}/IT-5/plist_contents.txt"; then
    echo "SELF-VERIFY FAIL: IT-5/plist_contents.txt missing ProgramArguments" >&2
    VERIFY_PASS=false
  fi
  if ! grep -q "KeepAlive" "${EVIDENCE_ROOT}/IT-5/plist_contents.txt"; then
    echo "SELF-VERIFY FAIL: IT-5/plist_contents.txt missing KeepAlive" >&2
    VERIFY_PASS=false
  fi
fi

echo ""
if [ "$ALL_PASS" != "true" ]; then
  echo "FAIL: One or more integration tests failed" >&2
  exit 1
fi

if [ "$VERIFY_PASS" != "true" ]; then
  echo "FAIL: Self-verification checks failed" >&2
  exit 1
fi

echo "ALL PASS: IT-1 through IT-5 passed with valid evidence"

# Clear the failure trap and just clean up
trap 'cleanup' EXIT
