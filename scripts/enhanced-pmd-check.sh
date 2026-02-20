#!/bin/bash
# Enhanced PMD Check Script (Fallback when PMD is not available)
# Performs basic code quality checks using grep/awk
# Non-blocking mode: Shows violations but doesn't fail the workflow

set +e  # Don't exit on errors - just report violations

CHANGED_SOURCES_DIR="${1:-changed-sources/force-app}"

echo "[INFO] Running enhanced PMD checks on: $CHANGED_SOURCES_DIR"

# Find Apex classes
APEX_FILES=$(find "$CHANGED_SOURCES_DIR" -name "*.cls" -not -name "*.cls-meta.xml" 2>/dev/null || true)

if [ -z "$APEX_FILES" ] || [ "$APEX_FILES" = "" ]; then
  echo "[INFO] No Apex classes found. Enhanced checks passed."
  exit 0
fi

VIOLATION_COUNT=0
VIOLATIONS_FOUND=""

for APEX_FILE in $APEX_FILES; do
  FILE_VIOLATIONS=0
  FILE_NAME=$(basename "$APEX_FILE")
  
  echo "[DEBUG] Checking file: $FILE_NAME"
  
  # Check 1: SOQL in loops
  AWK_RESULT=$(awk '
    /for\s*\(|while\s*\(/ { in_loop=1; loop_brace=0 }
    in_loop && /\{/ { loop_brace++ }
    in_loop && loop_brace > 0 && /\[SELECT/ { found_soql=1 }
    in_loop && /\}/ { 
      loop_brace--
      if (loop_brace == 0) { in_loop=0 }
    }
    END { exit !found_soql }
  ' "$APEX_FILE" 2>&1)
  AWK_EXIT=$?
  
  if [ $AWK_EXIT -eq 0 ]; then
    echo "[ERROR] $FILE_NAME: SOQL query inside loop detected (Performance violation)"
    VIOLATIONS_FOUND="${VIOLATIONS_FOUND}\n- $FILE_NAME: SOQL in loop"
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    echo "[DEBUG] SOQL violation detected in $FILE_NAME"
  fi
  
  # Check 2: DML in loops
  AWK_RESULT=$(awk '
    /for\s*\(|while\s*\(/ { in_loop=1; loop_brace=0 }
    in_loop && /\{/ { loop_brace++ }
    in_loop && loop_brace > 0 && /\b(insert|update|delete|upsert|undelete)\s+/ { found_dml=1 }
    in_loop && /\}/ { 
      loop_brace--
      if (loop_brace == 0) { in_loop=0 }
    }
    END { exit !found_dml }
  ' "$APEX_FILE" 2>&1)
  AWK_EXIT=$?
  
  if [ $AWK_EXIT -eq 0 ]; then
    echo "[ERROR] $FILE_NAME: DML operation inside loop detected (Performance violation)"
    VIOLATIONS_FOUND="${VIOLATIONS_FOUND}\n- $FILE_NAME: DML in loop"
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    echo "[DEBUG] DML violation detected in $FILE_NAME"
  fi
  
  # Check 3: Empty catch blocks
  if grep -qE "catch\s*\([^)]*\)\s*\{\s*\}" "$APEX_FILE" 2>/dev/null || \
     grep -A 2 -E "catch\s*\([^)]*\)\s*\{" "$APEX_FILE" 2>/dev/null | grep -qE "^\s*\}" || \
     awk '/catch\s*\([^)]*\)\s*\{/{catch_line=NR; next} catch_line && NR==catch_line+1 && /^\s*\}/{empty=1} catch_line && NR>catch_line+1 && !/^\s*\/\//{catch_line=0} END{exit !empty}' "$APEX_FILE" 2>/dev/null; then
    echo "[ERROR] $FILE_NAME: Empty catch block detected (Best practice violation)"
    VIOLATIONS_FOUND="${VIOLATIONS_FOUND}\n- $FILE_NAME: Empty catch block"
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
  fi
  
  # Check 4: Hardcoded IDs
  if grep -qE "'00[0-9a-zA-Z]{15,18}'" "$APEX_FILE" 2>/dev/null; then
    echo "[WARN] $FILE_NAME: Hardcoded Salesforce ID detected (Best practice violation)"
    VIOLATIONS_FOUND="${VIOLATIONS_FOUND}\n- $FILE_NAME: Hardcoded ID"
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
  fi
  
  # Check 5: Basic syntax
  if ! grep -qE "(public|private|global|@isTest).*(class|interface)" "$APEX_FILE" 2>/dev/null; then
    echo "[ERROR] $FILE_NAME: Invalid Apex class structure"
    VIOLATIONS_FOUND="${VIOLATIONS_FOUND}\n- $FILE_NAME: Invalid class structure"
    FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
  fi
  
  if [ $FILE_VIOLATIONS -eq 0 ]; then
    echo "[INFO] Enhanced validation passed for: $FILE_NAME"
  fi
  
  VIOLATION_COUNT=$((VIOLATION_COUNT + FILE_VIOLATIONS))
done

# Debug: Show violation count
echo "[DEBUG] Total violations found: $VIOLATION_COUNT"

if [ $VIOLATION_COUNT -gt 0 ]; then
  echo "[WARN] ⚠️ ========================================="
  echo "[WARN] Found $VIOLATION_COUNT PMD violation(s) - Showing in summary (non-blocking):"
  echo "[WARN] ========================================="
  echo -e "$VIOLATIONS_FOUND"
  echo "[WARN] ========================================="
  # Save violations for summary
  echo "$VIOLATIONS_FOUND" > pmd-violations.txt 2>/dev/null || true
  echo "$VIOLATION_COUNT" > pmd-violation-count.txt 2>/dev/null || true
  exit 0  # Don't fail - just report
else
  echo "[INFO] ✅ Enhanced validation passed (PMD unavailable, but no violations found)"
  echo "0" > pmd-violation-count.txt 2>/dev/null || true
  exit 0
fi
