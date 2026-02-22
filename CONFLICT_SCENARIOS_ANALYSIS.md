# Conflict Scenarios Analysis

This document explains how the workflows handle conflicts in different scenarios.

## 🔍 Scenario Analysis

### Scenario 1: DevTrial2 PR Not Merged + Push to Same Feature Branch

**Example:**
- PR: `promo/113` → `CRM_DevTrial2` (NOT merged yet)
- New commit pushed to `feature/113`

**What Happens:**
1. ✅ Workflow triggers on push to `feature/113`
2. ✅ Creates/updates `promo/113` branch
3. ✅ **Existing PR is updated** (not a new PR created)
4. ✅ New commit is added to the same PR
5. ✅ All validations run again (PMD, tests)
6. ✅ PR body is updated with latest results

**Conflict Risk:** ✅ **NO CONFLICTS** - The workflow handles this gracefully:
- Uses `git push --force-with-lease` for safe updates
- Updates existing PR instead of creating duplicate
- Resets promotional branch to base before merging new commits

**Code Reference:**
```yaml
# Check if PR already exists
const { data: existingPRs } = await github.rest.pulls.list({
  head: `${context.repo.owner}:${promoBranch}`,
  base: 'CRM_DevTrial2',
  state: 'open'
});

if (existingPRs.length > 0) {
  // Update existing PR
  await github.rest.pulls.update({
    pull_number: existingPR.number,
    body: prBody
  });
}
```

---

### Scenario 2: DevTrial2 PR Not Merged + Push to Different Feature Branch

**Example:**
- PR: `promo/113` → `CRM_DevTrial2` (NOT merged yet)
- New commit pushed to `feature/114` (different feature)

**What Happens:**
1. ✅ Workflow triggers on push to `feature/114`
2. ✅ Creates **new** `promo/114` branch (different from `promo/113`)
3. ✅ Creates **new** PR: `promo/114` → `CRM_DevTrial2`
4. ✅ Both PRs exist independently:
   - PR #1: `promo/113` → `CRM_DevTrial2` (still open)
   - PR #2: `promo/114` → `CRM_DevTrial2` (new)

**Conflict Risk:** ✅ **NO CONFLICTS** - Different branches, different PRs:
- Each feature branch creates its own promotional branch
- Branch naming: `promo/{feature_number}`
- Feature 113 → `promo/113`
- Feature 114 → `promo/114`
- They don't interfere with each other

**Code Reference:**
```bash
FEATURE_NUM=$(echo "$FEATURE_BRANCH" | sed 's/feature\///g')
PROMO_BRANCH="promo/$FEATURE_NUM"
# Each feature gets its own promo branch
```

---

### Scenario 3: SIT PR Not Merged + Push to Same Feature Branch

**Example:**
- PR: `sit-promo/113` → `CRM_SITTrial` (NOT merged yet)
- New commit pushed to `feature/113`

**What Happens:**
1. ✅ New commit in `feature/113` triggers workflow
2. ✅ Creates/updates `promo/113` → `CRM_DevTrial2` PR
3. ✅ If that PR is merged → Creates/updates `sit-promo/113` → `CRM_SITTrial` PR
4. ✅ **Existing SIT PR is updated** (not a new PR created)
5. ✅ Uses `git reset --hard` to reset `sit-promo/113` to base before merging

**Conflict Risk:** ✅ **NO CONFLICTS** - The workflow handles this:
- Resets promotional branch to base before merging
- Updates existing PR instead of creating duplicate
- Uses `git push --force-with-lease` for safe updates

**Code Reference:**
```yaml
# Check if SIT promotional branch already exists
if git ls-remote --heads origin "$SIT_PROMO_BRANCH" | grep -q "$SIT_PROMO_BRANCH"; then
  echo "[INFO] SIT promotional branch already exists"
  git reset --hard origin/$BASE_BRANCH  # Reset to clean state
  # Then merge new commit
fi
```

---

### Scenario 4: SIT PR Not Merged + Push to Different Feature Branch

**Example:**
- PR: `sit-promo/113` → `CRM_SITTrial` (NOT merged yet)
- New commit pushed to `feature/114` (different feature)

**What Happens:**
1. ✅ Workflow triggers on push to `feature/114`
2. ✅ Creates **new** `promo/114` branch
3. ✅ Creates **new** PR: `promo/114` → `CRM_DevTrial2`
4. ✅ If that PR is merged → Creates **new** `sit-promo/114` branch
5. ✅ Creates **new** PR: `sit-promo/114` → `CRM_SITTrial`
6. ✅ Both SIT PRs exist independently:
   - PR #1: `sit-promo/113` → `CRM_SITTrial` (still open)
   - PR #2: `sit-promo/114` → `CRM_SITTrial` (new)

**Conflict Risk:** ✅ **NO CONFLICTS** - Different branches, different PRs:
- Each feature gets its own `sit-promo/{feature_number}` branch
- Feature 113 → `sit-promo/113`
- Feature 114 → `sit-promo/114`
- They don't interfere with each other

---

## 🛡️ Conflict Prevention Mechanisms

### 1. Branch Naming Convention
- **Feature branches:** `feature/{number}` → Unique per feature
- **Promotional branches:** `promo/{number}` → Unique per feature
- **SIT promotional branches:** `sit-promo/{number}` → Unique per feature

**Result:** Different features never share the same promotional branch.

### 2. PR Update Logic
- Checks if PR already exists before creating
- Updates existing PR instead of creating duplicate
- Uses `state: 'open'` filter to find active PRs

**Code:**
```javascript
const { data: existingPRs } = await github.rest.pulls.list({
  head: `${context.repo.owner}:${promoBranch}`,
  base: 'CRM_DevTrial2',
  state: 'open'  // Only check open PRs
});

if (existingPRs.length > 0) {
  // Update existing PR
} else {
  // Create new PR
}
```

### 3. Safe Branch Updates
- Uses `git push --force-with-lease` instead of `git push --force`
- Prevents overwriting changes made outside the workflow
- Resets branch to base before merging new commits

**Code:**
```bash
# Reset to clean state before merging
git reset --hard origin/$BASE_BRANCH

# Safe force push
git push --force-with-lease origin $PROMO_BRANCH
```

### 4. Merge Conflict Detection
- Performs dry-run merge before actual merge
- Fails workflow if conflicts detected
- Aborts merge cleanly on conflict

**Code:**
```bash
# Try merge in dry-run mode first
git merge --no-commit --no-ff "$MERGE_COMMIT" || {
  echo "[ERROR] Merge conflict detected!"
  git merge --abort
  exit 1
}
```

### 5. Duplicate Commit Prevention
- Checks if commit is already merged before attempting merge
- Uses `git merge-base --is-ancestor` to detect duplicates

**Code:**
```bash
# Check if merge commit is already in branch
if git merge-base --is-ancestor "$MERGE_COMMIT" HEAD; then
  echo "[INFO] Merge commit already in branch"
  exit 0  # Skip merge
fi
```

---

## 📊 Summary Table

| Scenario | Same Feature Branch | Different Feature Branch |
|----------|-------------------|------------------------|
| **DevTrial2 PR Not Merged** | ✅ Updates existing PR<br>✅ No conflicts | ✅ Creates new PR<br>✅ No conflicts |
| **SIT PR Not Merged** | ✅ Updates existing PR<br>✅ No conflicts | ✅ Creates new PR<br>✅ No conflicts |

---

## ✅ Key Takeaways

1. **Same Feature Branch:** 
   - ✅ Existing PRs are **updated**, not duplicated
   - ✅ New commits are added to the same PR
   - ✅ No conflicts because branch is reset before merge

2. **Different Feature Branch:**
   - ✅ Each feature gets its own promotional branch
   - ✅ Each feature gets its own PR
   - ✅ No conflicts because branches are independent

3. **Conflict Prevention:**
   - ✅ Unique branch naming per feature
   - ✅ PR update logic prevents duplicates
   - ✅ Safe force push with `--force-with-lease`
   - ✅ Dry-run merge detects conflicts early
   - ✅ Branch reset ensures clean merge state

4. **Workflow Behavior:**
   - ✅ Handles existing branches gracefully
   - ✅ Updates PRs instead of creating duplicates
   - ✅ Fails safely on merge conflicts
   - ✅ Prevents duplicate commits

---

## 🚨 Edge Cases Handled

### Edge Case 1: Multiple Commits to Same Feature
**Scenario:** 5 commits pushed to `feature/113` before PR is merged

**Handling:**
- Each commit triggers workflow
- Each time, `promo/113` is updated
- PR is updated (not duplicated)
- Latest commit includes all previous commits (Git history)

### Edge Case 2: PR Closed Without Merge
**Scenario:** PR `promo/113` → `CRM_DevTrial2` is closed (not merged)

**Handling:**
- Workflow only runs on **merged** PRs (`merged == true`)
- Closed PRs don't trigger deployment
- Next push to `feature/113` creates new `promo/113` branch
- New PR is created (old one was closed)

### Edge Case 3: Concurrent Workflows
**Scenario:** Two commits pushed simultaneously to `feature/113`

**Handling:**
- GitHub Actions queues workflows
- Each workflow runs sequentially
- `git push --force-with-lease` prevents race conditions
- Last workflow wins (updates PR with latest commit)

---

## 🔧 Recommendations

### Best Practices:
1. ✅ **Merge PRs promptly** - Don't leave PRs open for too long
2. ✅ **One feature per branch** - Don't mix features in same branch
3. ✅ **Review PRs before merging** - Ensure quality before promotion
4. ✅ **Monitor workflow logs** - Check for any unexpected behavior

### If Conflicts Occur:
1. Check workflow logs for specific error
2. Verify branch naming follows convention
3. Ensure PRs are merged (not just closed)
4. Check if multiple workflows are running simultaneously

---

## 📝 Conclusion

**✅ The workflows are designed to handle all conflict scenarios gracefully:**

- Same feature branch pushes → Updates existing PR
- Different feature branch pushes → Creates new PR
- Existing branches → Reset and update safely
- Merge conflicts → Detected early and fail safely
- Duplicate commits → Prevented with ancestor checks

**No manual intervention needed!** The workflows handle everything automatically.
