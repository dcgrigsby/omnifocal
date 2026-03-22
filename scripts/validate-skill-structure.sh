#!/bin/sh
set -e

# --- Configuration ---
RUN_ID="${KILROY_RUN_ID:-01KM92J67JA36AA5PWJYNEVBRV}"
EVIDENCE_ROOT=".ai/runs/${RUN_ID}/test-evidence/latest"
SKILL_FILE="skills/omnifocal/SKILL.md"

trap 'echo "KILROY_VALIDATE_FAILURE: validate-skill-structure.sh failed" >&2' EXIT

echo "=== validate-skill-structure: IT-6 Skill Structure Validation ==="

# --- Setup evidence directories ---
mkdir -p "${EVIDENCE_ROOT}/IT-6"

RESULTS_FILE="${EVIDENCE_ROOT}/IT-6/skill_validation.txt"
> "$RESULTS_FILE"

ALL_PASS=true

# ========================================
# Check 1: File exists
# ========================================
echo "--- Check 1: File exists ---"
if [ -f "$SKILL_FILE" ]; then
  echo "PASS: frontmatter-exists: ${SKILL_FILE} exists" >> "$RESULTS_FILE"
  echo "Check 1: PASS - file exists"
else
  echo "FAIL: frontmatter-exists: ${SKILL_FILE} does not exist" >> "$RESULTS_FILE"
  echo "Check 1: FAIL - file does not exist" >&2
  ALL_PASS=false
fi

# ========================================
# Check 2: YAML frontmatter has name: and description:
# ========================================
echo "--- Check 2: YAML frontmatter ---"
# Extract frontmatter (between first --- and second ---)
# Use awk for portability (macOS sed differences)
FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_FILE")

HAS_NAME=$(echo "$FRONTMATTER" | grep -c '^name:' || true)
HAS_DESC=$(echo "$FRONTMATTER" | grep -c '^description:' || true)

if [ "$HAS_NAME" -ge 1 ] && [ "$HAS_DESC" -ge 1 ]; then
  echo "PASS: frontmatter: YAML frontmatter has name and description" >> "$RESULTS_FILE"
  echo "Check 2: PASS - frontmatter valid"
else
  echo "FAIL: frontmatter: Missing name ($HAS_NAME) or description ($HAS_DESC)" >> "$RESULTS_FILE"
  echo "Check 2: FAIL - frontmatter missing name or description" >&2
  ALL_PASS=false
fi

# ========================================
# Check 3: Under 500 lines
# ========================================
echo "--- Check 3: Line count ---"
LINE_COUNT=$(wc -l < "$SKILL_FILE" | tr -d ' ')

if [ "$LINE_COUNT" -lt 500 ]; then
  echo "PASS: line-count: ${LINE_COUNT} lines (under 500)" >> "$RESULTS_FILE"
  echo "Check 3: PASS - ${LINE_COUNT} lines"
else
  echo "FAIL: line-count: ${LINE_COUNT} lines (500 or more)" >> "$RESULTS_FILE"
  echo "Check 3: FAIL - ${LINE_COUNT} lines (too many)" >&2
  ALL_PASS=false
fi

# ========================================
# Check 4: No mutating patterns
# ========================================
echo "--- Check 4: No mutating patterns ---"
MUTATING_FOUND=false

# Check for save() - but not in "never call...save()" instruction context
# We need to be careful: the skill TALKS ABOUT save() to prohibit it.
# The DoD says the file must not CONTAIN these patterns.
# But AC-6.1 says "SKILL.md does not contain mutating patterns: save(), .name =, new Task, new Project, new Folder, new Tag"
# The tricky part: the skill references these in its "never do" instructions.
# Per the DoD IT-6 step 4: "Grep for mutating patterns (save(), .name =, new Task, new Project, new Folder, new Tag) -- must find ZERO matches."
# We need to check for actual usage patterns, not documentation of prohibitions.

# Check each pattern
for PATTERN in 'save()' '\.name =' 'new Task(' 'new Project(' 'new Folder(' 'new Tag('; do
  COUNT=$(grep -c "$PATTERN" "$SKILL_FILE" 2>/dev/null || true)
  if [ "$COUNT" -gt 0 ]; then
    echo "  Found mutating pattern '${PATTERN}' (${COUNT} occurrences)"
    MUTATING_FOUND=true
  fi
done

if [ "$MUTATING_FOUND" = "false" ]; then
  echo "PASS: no-mutating-patterns: No mutating patterns found" >> "$RESULTS_FILE"
  echo "Check 4: PASS - no mutating patterns"
else
  echo "FAIL: no-mutating-patterns: Mutating patterns detected in file" >> "$RESULTS_FILE"
  echo "Check 4: FAIL - mutating patterns found" >&2
  ALL_PASS=false
fi

# ========================================
# Check 5: Read-only enforcement text
# ========================================
echo "--- Check 5: Read-only enforcement text ---"
READONLY_COUNT=$(grep -ci 'read-only\|never assign\|never mutate' "$SKILL_FILE" 2>/dev/null || true)

if [ "$READONLY_COUNT" -ge 1 ]; then
  echo "PASS: read-only-text: Found ${READONLY_COUNT} read-only enforcement references" >> "$RESULTS_FILE"
  echo "Check 5: PASS - read-only text found (${READONLY_COUNT} matches)"
else
  echo "FAIL: read-only-text: No read-only enforcement text found" >> "$RESULTS_FILE"
  echo "Check 5: FAIL - no read-only text" >&2
  ALL_PASS=false
fi

# ========================================
# Check 6: Query patterns present
# ========================================
echo "--- Check 6: Query patterns ---"
QUERY_COUNT=$(grep -c 'flattenedTasks\|flattenedProjects' "$SKILL_FILE" 2>/dev/null || true)

if [ "$QUERY_COUNT" -ge 1 ]; then
  echo "PASS: query-patterns: Found ${QUERY_COUNT} query pattern references" >> "$RESULTS_FILE"
  echo "Check 6: PASS - query patterns found (${QUERY_COUNT} matches)"
else
  echo "FAIL: query-patterns: No query pattern references (flattenedTasks/flattenedProjects)" >> "$RESULTS_FILE"
  echo "Check 6: FAIL - no query patterns" >&2
  ALL_PASS=false
fi

# ========================================
# Check 7: JSON.stringify present
# ========================================
echo "--- Check 7: JSON.stringify ---"
STRINGIFY_COUNT=$(grep -c 'JSON.stringify' "$SKILL_FILE" 2>/dev/null || true)

if [ "$STRINGIFY_COUNT" -ge 1 ]; then
  echo "PASS: json-stringify: Found ${STRINGIFY_COUNT} JSON.stringify references" >> "$RESULTS_FILE"
  echo "Check 7: PASS - JSON.stringify found (${STRINGIFY_COUNT} matches)"
else
  echo "FAIL: json-stringify: No JSON.stringify references" >> "$RESULTS_FILE"
  echo "Check 7: FAIL - no JSON.stringify" >&2
  ALL_PASS=false
fi

# ========================================
# Check 8: POST instruction present
# ========================================
echo "--- Check 8: POST instruction ---"
POST_COUNT=$(grep -c 'POST' "$SKILL_FILE" 2>/dev/null || true)
EVAL_COUNT=$(grep -c '/eval' "$SKILL_FILE" 2>/dev/null || true)

if [ "$POST_COUNT" -ge 1 ] && [ "$EVAL_COUNT" -ge 1 ]; then
  echo "PASS: post-instruction: Found POST (${POST_COUNT}) and /eval (${EVAL_COUNT}) references" >> "$RESULTS_FILE"
  echo "Check 8: PASS - POST instruction found"
else
  echo "FAIL: post-instruction: Missing POST (${POST_COUNT}) or /eval (${EVAL_COUNT})" >> "$RESULTS_FILE"
  echo "Check 8: FAIL - POST or /eval missing" >&2
  ALL_PASS=false
fi

# ========================================
# Update manifest.json (append IT-6)
# ========================================
echo ""
echo "=== Updating manifest ==="

# Read existing manifest if present, or create fresh
if [ -f "${EVIDENCE_ROOT}/manifest.json" ]; then
  echo "Existing manifest found, adding IT-6 entry"
fi

# Write a standalone IT-6 manifest (the verify node can merge)
cat > "${EVIDENCE_ROOT}/IT-6/manifest_fragment.json" <<MANIFEST_EOF
{
  "IT-6": {
    "status": "$([ "$ALL_PASS" = "true" ] && echo "pass" || echo "fail")",
    "artifacts": [
      "IT-6/skill_validation.txt"
    ]
  }
}
MANIFEST_EOF

# ========================================
# SELF-VERIFICATION
# ========================================
echo ""
echo "=== Self-Verification ==="
VERIFY_PASS=true

# 1. Evidence file exists and is non-empty
if [ ! -s "$RESULTS_FILE" ]; then
  echo "SELF-VERIFY FAIL: skill_validation.txt is empty or missing" >&2
  VERIFY_PASS=false
fi

# 2. Evidence contains PASS entries
PASS_COUNT=$(grep -c 'PASS' "$RESULTS_FILE" 2>/dev/null || true)
if [ "$PASS_COUNT" -lt 1 ]; then
  echo "SELF-VERIFY FAIL: No PASS entries in evidence" >&2
  VERIFY_PASS=false
else
  echo "Self-verify: Found ${PASS_COUNT} PASS entries in evidence"
fi

# 3. No FAIL entries (if ALL_PASS)
if [ "$ALL_PASS" = "true" ]; then
  FAIL_COUNT=$(grep -c 'FAIL' "$RESULTS_FILE" 2>/dev/null || true)
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "SELF-VERIFY FAIL: Found FAIL entries despite ALL_PASS=true" >&2
    VERIFY_PASS=false
  fi
fi

echo ""
if [ "$ALL_PASS" != "true" ]; then
  echo "FAIL: One or more skill structure checks failed" >&2
  cat "$RESULTS_FILE"
  exit 1
fi

if [ "$VERIFY_PASS" != "true" ]; then
  echo "FAIL: Self-verification checks failed" >&2
  exit 1
fi

echo "ALL PASS: IT-6 skill structure validation passed"
cat "$RESULTS_FILE"

# Clear the failure trap
trap - EXIT
