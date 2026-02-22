# Workflow Trigger Explanation

## How Workflows Distinguish Between Deployments

### Workflow 1: `deploy-after-pr-approval.yml`
**Purpose:** Deploy to CRM_DevTrial org

**Trigger:**
- PR closed to `CRM_DevTrial2` branch

**Job Condition:**
```yaml
if: |
  github.event.pull_request.merged == true &&
  startsWith(github.event.pull_request.head.ref, 'promo/')
```

**What it does:**
- ✅ Runs when PR from `promo/XXX` → `CRM_DevTrial2` is merged
- ✅ Deploys to **CRM_DevTrial** org
- ❌ Does NOT run for SIT deployments

---

### Workflow 2: `sit-promotion-and-deployment.yml`
**Purpose:** Promote to SIT and deploy to CRM_SITOrg

**Trigger:**
- PR closed to `CRM_DevTrial2` OR `CRM_SITTrial` branches

**Job 1: `promote-to-sit`**
**Condition:**
```yaml
if: |
  github.event.pull_request.merged == true &&
  github.event.pull_request.base.ref == 'CRM_DevTrial2' &&
  startsWith(github.event.pull_request.head.ref, 'promo/')
```

**What it does:**
- ✅ Runs when PR from `promo/XXX` → `CRM_DevTrial2` is merged
- ✅ Creates `sit-promo/XXX` branch
- ✅ Creates PR to `CRM_SITTrial`
- ❌ Does NOT deploy (only promotes)

**Job 2: `deploy-to-sit-org`**
**Condition:**
```yaml
if: |
  github.event.pull_request.merged == true &&
  github.event.pull_request.base.ref == 'CRM_SITTrial' &&
  startsWith(github.event.pull_request.head.ref, 'sit-promo/')
```

**What it does:**
- ✅ Runs when PR from `sit-promo/XXX` → `CRM_SITTrial` is merged
- ✅ Deploys to **CRM_SITOrg**
- ❌ Does NOT run for CRM_DevTrial deployments

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: PR merged to CRM_DevTrial2 (from promo/XXX)        │
└─────────────────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────────┐   ┌──────────────────────────────┐
│ deploy-after-    │   │ sit-promotion-and-           │
│ pr-approval.yml  │   │ deployment.yml               │
│                  │   │ Job: promote-to-sit          │
│ ✅ Deploys to    │   │                              │
│ CRM_DevTrial org │   │ ✅ Creates sit-promo/XXX     │
│                  │   │ ✅ Creates PR to CRM_SITTrial│
└──────────────────┘   └──────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ Step 2: PR merged to          │
                    │ CRM_SITTrial (from sit-promo/)│
                    └───────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ sit-promotion-and-            │
                    │ deployment.yml                │
                    │ Job: deploy-to-sit-org        │
                    │                               │
                    │ ✅ Deploys to CRM_SITOrg      │
                    └───────────────────────────────┘
```

## Key Distinctions

### How Workflows Know Which Deployment to Run:

1. **`github.event.pull_request.base.ref`** - The target branch of the PR
   - `CRM_DevTrial2` → CRM_DevTrial deployment
   - `CRM_SITTrial` → CRM_SITOrg deployment

2. **`github.event.pull_request.head.ref`** - The source branch of the PR
   - `promo/XXX` → DevTrial promotion/deployment
   - `sit-promo/XXX` → SIT deployment

3. **Workflow File** - Different workflows handle different deployments
   - `deploy-after-pr-approval.yml` → Only CRM_DevTrial
   - `sit-promotion-and-deployment.yml` → SIT promotion + CRM_SITOrg

## Example Scenarios

### Scenario 1: PR merged to CRM_DevTrial2
**PR:** `promo/113` → `CRM_DevTrial2` (merged)

**Triggers:**
- ✅ `deploy-after-pr-approval.yml` → Deploys to CRM_DevTrial org
- ✅ `sit-promotion-and-deployment.yml` → `promote-to-sit` job runs → Creates sit-promo/113 and PR

### Scenario 2: PR merged to CRM_SITTrial
**PR:** `sit-promo/113` → `CRM_SITTrial` (merged)

**Triggers:**
- ✅ `sit-promotion-and-deployment.yml` → `deploy-to-sit-org` job runs → Deploys to CRM_SITOrg
- ❌ `deploy-after-pr-approval.yml` → Does NOT run (only listens to CRM_DevTrial2)

## Summary

✅ **CRM_DevTrial deployment:** Handled by `deploy-after-pr-approval.yml` when PR to `CRM_DevTrial2` is merged

✅ **CRM_SITOrg deployment:** Handled by `sit-promotion-and-deployment.yml` → `deploy-to-sit-org` job when PR to `CRM_SITTrial` is merged

The workflows use `base.ref` and `head.ref` to correctly identify which deployment to run!
