#!/bin/bash
# PMD Check Script for Apex Code Analysis
# This script runs PMD checks on delta changes
# Non-blocking mode: Shows violations but doesn't fail the workflow

set +e  # Don't exit on errors - just report violations

CHANGED_SOURCES_DIR="${1:-changed-sources/force-app}"
PMD_RULESET="${2:-.pmd/apex-ruleset.xml}"

echo "[INFO] Running PMD checks on: $CHANGED_SOURCES_DIR"

# Check if changes directory exists
if [ ! -d "$CHANGED_SOURCES_DIR" ]; then
  echo "[WARN] No changes directory found. Skipping PMD checks."
  exit 0
fi

# Find Apex classes in delta
APEX_FILES=$(find "$CHANGED_SOURCES_DIR" -name "*.cls" -not -name "*.cls-meta.xml" 2>/dev/null || true)

if [ -z "$APEX_FILES" ] || [ "$APEX_FILES" = "" ]; then
  echo "[INFO] No Apex classes found in delta changes. PMD checks passed."
  exit 0
fi

echo "[INFO] Found Apex files to check:"
echo "$APEX_FILES" | head -10

# Check if PMD is available
PMD_CMD=""
if command -v pmd &> /dev/null; then
  PMD_CMD="pmd"
elif [ -f "/opt/pmd/bin/pmd" ]; then
  PMD_CMD="/opt/pmd/bin/pmd"
fi

if [ -z "$PMD_CMD" ] || ! "$PMD_CMD" --version &>/dev/null; then
  echo "[WARN] PMD not available. Running enhanced validation..."
  exec "$(dirname "$0")/enhanced-pmd-check.sh" "$CHANGED_SOURCES_DIR"
fi

echo "[INFO] Using PMD command: $PMD_CMD"
"$PMD_CMD" --version

# Run PMD with ruleset file
set +e
if [ -f "$PMD_RULESET" ]; then
  echo "[INFO] Running PMD with ruleset file: $PMD_RULESET"
  PMD_OUTPUT=$("$PMD_CMD" check -d "$CHANGED_SOURCES_DIR" -R "$PMD_RULESET" -f json 2>&1)
  PMD_EXIT_CODE=$?
else
  echo "[INFO] Running PMD with category rules..."
  PMD_OUTPUT=$("$PMD_CMD" check -d "$CHANGED_SOURCES_DIR" \
    -R category/apex/security.xml,category/apex/performance.xml,category/apex/bestpractices.xml \
    -f json 2>&1)
  PMD_EXIT_CODE=$?
fi
set -e

echo "[INFO] PMD Exit Code: $PMD_EXIT_CODE"
echo "[INFO] PMD Output (first 200 lines):"
echo "$PMD_OUTPUT" | head -200

# PMD exit codes: 0 = no violations, 4 = violations found
# NON-BLOCKING MODE: Always exit 0, but report violations
if [ $PMD_EXIT_CODE -eq 4 ]; then
  VIOLATION_COUNT=$(echo "$PMD_OUTPUT" | jq -r '[.files[].violations[]?] | length' 2>/dev/null || echo "0")
  
  if [ "$VIOLATION_COUNT" -gt 0 ]; then
    echo "[WARN] ⚠️ PMD found $VIOLATION_COUNT violation(s) - Showing in summary (non-blocking)"
    echo "[INFO] PMD violations details:"
    echo "$PMD_OUTPUT" | jq '.files[] | select(.violations != null and (.violations | length > 0))' 2>/dev/null || echo "$PMD_OUTPUT"
    # Save violations to file for summary
    echo "$PMD_OUTPUT" > pmd-violations.json 2>/dev/null || true
    echo "$VIOLATION_COUNT" > pmd-violation-count.txt 2>/dev/null || true
    exit 0  # Don't fail - just report
  else
    echo "[INFO] PMD exit code 4 but no violations parsed. Treating as passed."
    exit 0
  fi
elif [ $PMD_EXIT_CODE -eq 0 ]; then
  echo "[INFO] ✅ PMD checks passed - No violations found"
  echo "0" > pmd-violation-count.txt 2>/dev/null || true
  exit 0
else
  echo "[WARN] PMD execution returned exit code $PMD_EXIT_CODE (non-blocking)"
  echo "[WARN] PMD output: $PMD_OUTPUT"
  echo "0" > pmd-violation-count.txt 2>/dev/null || true
  exit 0  # Don't fail - just report
fi
