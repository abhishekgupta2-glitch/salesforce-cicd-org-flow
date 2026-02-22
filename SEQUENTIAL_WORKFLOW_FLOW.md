# Sequential Workflow Flow - SIT Promotion and Deployment

## 🔄 Sequential Execution Flow

The workflow is designed to execute **sequentially**, not simultaneously:

```
Step 1: CRM_DevTrial2 PR Merged
   ↓
Step 2: promote-to-sit Job Runs
   ├─ Creates sit-promo/XXX branch
   ├─ Runs PMD checks
   ├─ Runs Apex tests
   └─ Creates PR: sit-promo/XXX → CRM_SITTrial
   ↓
Step 3: PR to CRM_SITTrial is Merged (Manual Review & Approval)
   ↓
Step 4: deploy-to-sit-org Job Runs
   ├─ Deploys to CRM_SITOrg
   ├─ Runs Apex tests
   └─ Validates code coverage
```

---

## 🛡️ How Sequential Execution is Enforced

### 1. **Job-Level `if` Conditions**

Each job has strict conditions that prevent it from running at the wrong time:

#### `promote-to-sit` Job:
```yaml
if: |
  github.event.pull_request.merged == true &&
  github.event.pull_request.base.ref == 'CRM_DevTrial2' &&
  startsWith(github.event.pull_request.head.ref, 'promo/')
```

**This job ONLY runs when:**
- ✅ PR to `CRM_DevTrial2` is merged
- ✅ PR is from a `promo/` branch
- ❌ Does NOT run when PR to `CRM_SITTrial` is merged

#### `deploy-to-sit-org` Job:
```yaml
if: |
  github.event.pull_request.merged == true &&
  github.event.pull_request.base.ref == 'CRM_SITTrial' &&
  startsWith(github.event.pull_request.head.ref, 'sit-promo/')
```

**This job ONLY runs when:**
- ✅ PR to `CRM_SITTrial` is merged
- ✅ PR is from a `sit-promo/` branch
- ❌ Does NOT run when PR to `CRM_DevTrial2` is merged

---

### 2. **Step-Level Validation**

Both jobs include explicit validation steps that **exit early** if triggered incorrectly:

#### In `promote-to-sit` Job:
```bash
# Step 7: Verify Trigger and Extract Feature Number
BASE_REF="${{ github.event.pull_request.base.ref }}"

if [ "$BASE_REF" != "CRM_DevTrial2" ]; then
  echo "[ERROR] This job should only run for PRs to CRM_DevTrial2"
  exit 1  # ← Stops execution immediately
fi
```

#### In `deploy-to-sit-org` Job:
```bash
# Step 7: Verify PR Merge Status and Trigger Validation
BASE_REF="${{ github.event.pull_request.base.ref }}"

if [ "$BASE_REF" != "CRM_SITTrial" ]; then
  echo "[ERROR] This job should only run for PRs to CRM_SITTrial"
  exit 1  # ← Stops execution immediately
fi
```

---

## 📊 Execution Timeline

### Scenario: PR to CRM_DevTrial2 is Merged

**Time T0:** PR `promo/113` → `CRM_DevTrial2` is merged

**Time T1:** Workflow triggers
- ✅ `promote-to-sit` job: **RUNS** (conditions met)
- ❌ `deploy-to-sit-org` job: **SKIPPED** (base.ref != 'CRM_SITTrial')

**Time T2:** `promote-to-sit` completes
- Creates `sit-promo/113` branch
- Creates PR: `sit-promo/113` → `CRM_SITTrial`
- **Workflow ends**

**Time T3:** (Manual step) PR `sit-promo/113` → `CRM_SITTrial` is reviewed and merged

**Time T4:** New workflow triggers
- ❌ `promote-to-sit` job: **SKIPPED** (base.ref != 'CRM_DevTrial2')
- ✅ `deploy-to-sit-org` job: **RUNS** (conditions met)

**Time T5:** `deploy-to-sit-org` completes
- Deploys to `CRM_SITOrg`
- **Workflow ends**

---

## ✅ Verification

### How to Verify Sequential Execution:

1. **Check GitHub Actions Logs:**
   - When `CRM_DevTrial2` PR is merged → Only `promote-to-sit` should run
   - When `CRM_SITTrial` PR is merged → Only `deploy-to-sit-org` should run

2. **Look for Validation Messages:**
   ```
   [INFO] Checking if this is the correct trigger for SIT promotion...
   [INFO] Base branch: CRM_DevTrial2
   [INFO] ✅ Valid trigger confirmed
   ```

3. **Check Job Status:**
   - Jobs that don't meet conditions will show as "Skipped" in GitHub Actions UI

---

## 🚨 Troubleshooting

### Issue: Both jobs running simultaneously

**Possible Causes:**
1. ❌ Job `if` conditions not working correctly
2. ❌ Step-level validation not added
3. ❌ Multiple workflows triggering

**Solution:**
- ✅ Verify `if` conditions are correct (see above)
- ✅ Check that validation steps are present
- ✅ Ensure only one workflow file handles these triggers

### Issue: `deploy-to-sit-org` runs when `CRM_DevTrial2` PR is merged

**Check:**
1. Verify `base.ref` in the workflow logs
2. Check if validation step exits early
3. Verify `if` condition syntax

**Expected Behavior:**
- Job should be **skipped** (not run)
- Validation step should **exit with error** if it somehow runs

---

## 📝 Summary

**✅ Sequential Execution is Guaranteed By:**

1. **Job-level `if` conditions** - Prevent jobs from running at wrong times
2. **Step-level validation** - Exit early if triggered incorrectly
3. **Separate PR merges** - Each stage requires a separate PR merge event
4. **Explicit branch checks** - Verify `base.ref` matches expected branch

**The workflow CANNOT run both jobs simultaneously because:**
- When `CRM_DevTrial2` PR merges → Only `promote-to-sit` conditions are met
- When `CRM_SITTrial` PR merges → Only `deploy-to-sit-org` conditions are met
- Each job validates its trigger and exits if incorrect

**Result:** ✅ **True sequential execution** - One job completes before the next can start.
