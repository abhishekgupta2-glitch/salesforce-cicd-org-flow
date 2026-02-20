# Workflow Trigger Explanation

## Expected Behavior

When you **push to a feature branch** (e.g., `feature/113`), only **ONE** workflow should trigger:

### ✅ Should Trigger:
- **`validate-pr-against-sit.yml`** - This is the ONLY workflow that should run on feature branch push
  - Trigger: `push` to `feature/**` branches
  - Purpose: Validates code, creates promotional branch, creates PR

### ❌ Should NOT Trigger:
- **`deploy-after-pr-approval.yml`** - Should only run when PR is **merged** to `CRM_DevTrial2`
  - Trigger: `pull_request` with `types: [closed]` to `CRM_DevTrial2`
  - Condition: `github.event.pull_request.merged == true` AND `promo/` branch
  
- **`sit-promotion-and-deployment.yml`** - Should only run when PR is **merged** to `CRM_DevTrial2`
  - Trigger: `pull_request` with `types: [closed]` to `CRM_DevTrial2`
  - Condition: `github.event.pull_request.merged == true` AND `promo/` branch

## Why You Might See Multiple Workflows

If you're seeing all 3 workflows trigger when pushing to a feature branch, it could be due to:

1. **Open PR Exists**: If there's already an open PR from your feature branch to `CRM_DevTrial2`, GitHub might show the PR workflows as "triggered" but they should fail immediately due to the `if` conditions.

2. **Workflow Syntax Errors**: YAML syntax errors can cause workflows to appear as "triggered" even when they shouldn't run. These have been fixed.

3. **GitHub Actions Behavior**: Sometimes GitHub shows workflows as "triggered" but they exit immediately if conditions aren't met.

## How to Verify

1. **Check the workflow run details**: Click on each workflow run
2. **Look for the job status**: Jobs with conditions that fail should show as "skipped" or exit immediately
3. **Check the logs**: The deployment workflows should show "Skipped" if triggered incorrectly

## Correct Flow

```
Push to feature/113
    ↓
validate-pr-against-sit.yml runs ✅
    ├─ Creates promo/113 branch
    ├─ Runs PMD checks
    ├─ Runs Apex tests
    └─ Creates PR to CRM_DevTrial2
         ↓
    PR Approved & Merged
         ↓
deploy-after-pr-approval.yml runs ✅
    └─ Deploys to CRM_DevTrial org
         ↓
sit-promotion-and-deployment.yml (Job 1) runs ✅
    └─ Creates sit-promo/113 branch
    └─ Creates PR to CRM_SITTrial
         ↓
    PR Approved & Merged
         ↓
sit-promotion-and-deployment.yml (Job 2) runs ✅
    └─ Deploys to CRM_SITOrg
```

## If Workflows Still Trigger Incorrectly

If workflows are still triggering when they shouldn't:

1. **Check for syntax errors**: All YAML syntax errors have been fixed
2. **Verify branch protection**: Ensure branch protection rules are set correctly
3. **Check workflow conditions**: The `if` conditions should prevent incorrect runs
4. **Review GitHub Actions logs**: Check why workflows are running

## Fixed Issues

✅ Fixed YAML syntax errors on lines 282 and 506
✅ Added explicit `paths-ignore` to PR workflows
✅ Improved template string formatting to avoid YAML parsing issues
✅ Added clear conditions to prevent incorrect workflow runs
