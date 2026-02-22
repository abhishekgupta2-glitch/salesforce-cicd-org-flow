# Test Validation Against Promotional Branch - Explanation

## What Happens When Tests Run Against Promotional Branch

When you push to a feature branch, the workflow creates a promotional branch (`promo/XXX`) and runs test validation **before** deployment to the org.

## Current Behavior

### What It Tests:

The `run-apex-tests.sh` script performs **syntax and structure validation** of test classes:

1. **Finds Test Classes:**
   - Searches for `*Test.cls` files in the promotional branch
   - Validates they exist and are properly named

2. **Validates Test Class Structure:**
   - ✅ Checks for `@isTest` annotation on class
   - ✅ Checks for test methods with `@isTest`, `@Test`, or `testMethod` keyword
   - ✅ Validates test method signatures
   - ✅ Checks for empty test methods
   - ✅ Verifies class declaration is valid

3. **Checks for Required Tests:**
   - ℹ️ If Apex classes exist but no test classes found → **INFO ONLY** (doesn't fail)
   - ℹ️ Recognizes that test classes may exist elsewhere or coverage provided by other tests
   - ✅ Full coverage validation happens after deployment to org

4. **What It Does NOT Do:**
   - ❌ Does NOT actually execute tests (no org connection)
   - ❌ Does NOT check test results
   - ❌ Does NOT validate test logic or assertions

### Why It Might Not Fail:

**Previous Issue:**
- Script always exited with code 0 (success)
- Even if validation found issues, it created a mock success result
- No actual test execution happened

**Fixed Now:**
- ✅ Script now fails if:
  - Apex classes exist but no test classes found
  - Test classes have invalid structure
  - Test methods are missing annotations
  - Test classes are empty or malformed

## What Gets Validated:

### 1. Test Class Existence
```bash
# Finds: *Test.cls files
# Validates: File exists and is properly named
```

### 2. Test Class Annotations
```bash
# Checks for: @isTest annotation
# Validates: Class is marked as test class
```

### 3. Test Method Annotations
```bash
# Checks for: @isTest, @Test, or testMethod
# Validates: Methods are properly marked as tests
```

### 4. Test Method Structure
```bash
# Checks for: Valid method signatures
# Validates: Methods follow proper syntax
```

### 5. Empty Test Detection
```bash
# Checks for: Empty test methods {}
# Validates: Tests have actual code
```

### 6. Required Test Classes
```bash
# Checks for: Test classes for all Apex classes
# Validates: Coverage requirements met
```

## When It Fails:

The validation will **FAIL** if:

1. ❌ **Test class missing @isTest annotation:**
   ```
   [WARN] MyTestClass: Missing @isTest annotation
   [ERROR] Test class validation failed
   ```

2. ❌ **Test methods not properly annotated:**
   ```
   [WARN] MyTestClass: No test method annotations found
   [ERROR] Test class validation failed
   ```

3. ❌ **Invalid class structure:**
   ```
   [ERROR] MyTestClass: Invalid class declaration
   [ERROR] Test class validation failed
   ```

## When It Passes:

The validation will **PASS** if:

1. ✅ Test classes exist and are properly structured (if any test classes in changes)
2. ✅ Test methods are correctly annotated
3. ✅ No Apex classes in changes (or Apex classes exist but test classes may be elsewhere)
4. ✅ All validations pass

**Important:** The validation does NOT require every Apex class to have its own test class. It recognizes that:
- Test classes may exist in other parts of the codebase
- One test class can cover multiple Apex classes
- Coverage validation happens after deployment to org

## Full Test Execution:

**Important:** The validation against the promotional branch is **syntax validation only**.

**Full test execution happens:**
- ✅ After deployment to CRM_DevTrial org
- ✅ After deployment to CRM_SITOrg
- ✅ Uses `sf apex run test --test-level RunLocalTests`
- ✅ Validates actual test results and code coverage

## Example Output:

### Success Case:
```
[INFO] Running Apex test validation against promotional branch code...
[INFO] Found test classes:
force-app/main/default/classes/MyTest.cls
[INFO] Test classes to validate: MyTest
[INFO] MyTest: Found 3 test method(s) with @isTest annotation
[INFO] ✅ Test class validation PASSED
[INFO] Test classes found: 1
[INFO] Validation errors: 0
```

### No Test Classes Case (Passes):
```
[INFO] Running Apex test validation against promotional branch code...
[INFO] No test classes found in force-app
[INFO] Found 2 Apex class(es) in changes:
  - MyApexClass
  - AnotherClass
[INFO] ℹ️  Note: Test classes may exist elsewhere or coverage may be provided by other tests
[INFO] ℹ️  Full test coverage validation will happen after deployment to org
[INFO] ✅ Test class validation passed (no test classes in changes to validate)
```

### Failure Case (Invalid Test Class Structure):
```
[INFO] Running Apex test validation against promotional branch code...
[INFO] Found test classes:
force-app/main/default/classes/MyTest.cls
[WARN] MyTest: Missing @isTest annotation
[ERROR] Test class validation failed
```

## Summary:

- **Promotional Branch Validation:** Syntax and structure checks only
- **Org Deployment Validation:** Full test execution with results and coverage
- **Purpose:** Catch issues early before deployment
- **Failure:** Prevents deployment if test classes have invalid structure
- **Does NOT Require:** Every Apex class to have its own test class
- **Recognizes:** Test classes may exist elsewhere or cover multiple classes
- **Coverage Validation:** Happens after deployment to org (75% threshold)
