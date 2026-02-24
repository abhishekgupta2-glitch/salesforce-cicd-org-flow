# CI/CD Workflow Summary

## Overview

This repository implements a multi-stage CI/CD pipeline for Salesforce deployments across two environments:
1. **CRM_DevTrial** - Development/Testing environment
2. **CRM_SITOrg** - System Integration Testing environment

**Branch Strategy:** Feature branches are created from `CRM_DevTrial2` (not main). `CRM_DevTrial2` is the integration branch for development; `main` is production-ready and updated last.

---

## Workflow Files

### 1. `validate-pr-against-sit.yml`
**Name:** Feature Branch Validation and Promotion

**Purpose:** Validate feature branches and create PRs to CRM_DevTrial2

**Triggers:** Push to `feature/*` or `feature/**` branches

**Steps:**
1. Checkout feature branch
2. Install Salesforce CLI, sfdx-git-delta, jq, bc
3. Create promotional branch (`promo/*`) from `CRM_DevTrial2`
4. Validate merge (dry-run) – detect conflicts; fail with instructions if feature branch diverges from CRM_DevTrial2
5. Merge feature branch into promotional branch
6. Generate delta packages
7. Run PMD checks (non-blocking)
8. Run Apex test class structure validation (`scripts/run-apex-tests.sh`)
9. Push promotional branch
10. Create/update PR to `CRM_DevTrial2`

**Key Features:**
- Promotional branch based on `CRM_DevTrial2`
- Conflict detection with clear instructions to merge `CRM_DevTrial2` into feature branch
- Updates existing PRs instead of creating duplicates
- Test validation failure: closes PR and deletes promotional branch

---

### 2. `deploy-after-pr-approval.yml`
**Name:** Deploy to CRM_DevTrial after PR Merge

**Purpose:** Deploy to CRM_DevTrial org and promote to SIT (sequential)

**Triggers:** PR merged to `CRM_DevTrial2` (from `promo/*` branches). Skips revert PRs.

**Two Jobs (sequential):**

#### Job 1: `deploy-after-merge`
**Steps:**
1. Checkout merge commit
2. Verify PR merge status
3. Generate delta packages (sf sgd)
4. Authorize CRM_DevTrial org (JWT)
5. **Pre-deployment validation** (like Change Sets):
   - `sf project deploy validate` – syntax check
   - `sf project deploy start --test-level RunLocalTests` – deploy with tests; Salesforce rolls back automatically if tests fail
6. Verify deployment success and coverage (≥75%)
7. Post-deployment coverage verification
8. **On failure:** Create revert PR, auto-merge it, add labels to skip SIT
9. Comment on PR with deployment status

**Key Features:**
- Pre-deployment validation: tests run during deploy; Salesforce rolls back on failure
- Auto-revert PR on test/coverage failure
- Correct JSON parsing for Salesforce deploy response (`numberTestsCompleted`, `runTestResult`)

#### Job 2: `promote-to-sit`
**Runs only when:** Job 1 succeeds and has changes

**Steps:**
1. Create SIT promotional branch (`sit-promo/*`) from `CRM_SITTrial`
2. Merge CRM_DevTrial2 merge commit into sit-promo branch
3. Generate delta packages
4. Run PMD checks
5. Run Apex test validation
6. Push SIT promotional branch
7. Create/update PR to `CRM_SITTrial`

**Key Features:**
- Runs only after successful DevTrial deployment
- Sequential: DevTrial deploy → SIT promotion

---

### 3. `sit-promotion-and-deployment.yml`
**Name:** SIT Environment Deployment (CRM_SITTrial PR → CRM_SITOrg)

**Purpose:** Deploy to CRM_SITOrg when SIT PR is merged

**Triggers:** PR merged to `CRM_SITTrial` (from `sit-promo/*` branches). Skips revert PRs.

**Job: `deploy-to-sit-org`**

**Steps:**
1. Checkout merge commit
2. Verify PR merge status
3. Generate delta packages
4. Authorize CRM_SITOrg (JWT)
5. Pre-deployment validation (same as DevTrial)
6. Deploy with `--test-level RunLocalTests`
7. Verify coverage (≥75%)
8. Post-deployment coverage verification
9. **On failure:** Create revert PR, auto-merge it
10. Comment on PR with deployment status

**Key Features:**
- Same validation pattern as DevTrial
- Skips when revert PRs are merged

---

## Complete Flow Diagram

```
Feature Branch (feature/XXX) ← created from CRM_DevTrial2
    │
    │ push
    ▼
[validate-pr-against-sit.yml]
    ├─ Create promo/XXX from CRM_DevTrial2
    ├─ Merge feature/XXX into promo/XXX
    ├─ PMD checks, Apex test validation
    └─ Create/Update PR to CRM_DevTrial2
         │
         │ PR merged
         ▼
[deploy-after-pr-approval.yml - Job 1: deploy-after-merge]
    ├─ Delta generation
    ├─ Pre-deploy validation (deploy + RunLocalTests)
    ├─ Deploy to CRM_DevTrial org
    ├─ Coverage check (≥75%)
    └─ On failure: auto-revert PR
         │
         │ Success
         ▼
[deploy-after-pr-approval.yml - Job 2: promote-to-sit]
    ├─ Create sit-promo/XXX from CRM_SITTrial
    ├─ Merge CRM_DevTrial2 changes
    ├─ PMD, Apex validation
    └─ Create/Update PR to CRM_SITTrial
         │
         │ PR merged
         ▼
[sit-promotion-and-deployment.yml - deploy-to-sit-org]
    ├─ Delta generation
    ├─ Pre-deploy validation
    ├─ Deploy to CRM_SITOrg
    └─ Coverage check (≥75%)
```

---

## Branch Strategy

| Branch Type | Pattern | Base Branch |
|-------------|---------|-------------|
| Feature branches | `feature/XXX` | **CRM_DevTrial2** |
| DevTrial promotional | `promo/XXX` | CRM_DevTrial2 |
| SIT promotional | `sit-promo/XXX` | CRM_SITTrial |
| Integration branches | `CRM_DevTrial2`, `CRM_SITTrial` | — |
| Production-ready | `main` | — |

---

## Key Features

1. **Feature branches from CRM_DevTrial2** – Development work is based on the DevTrial integration branch.
2. **Pre-deployment validation** – Deploy with `--test-level RunLocalTests`; Salesforce rolls back on test failure.
3. **Auto-revert on failure** – Revert PR created and auto-merged when tests/coverage fail; SIT workflows skip revert PRs.
4. **Sequential SIT promotion** – SIT promotion runs only after successful DevTrial deployment.
5. **PR update, not duplicate** – Existing PRs are updated when new commits are pushed.
6. **Non-blocking PMD** – PMD runs but does not fail the workflow.
7. **Test validation** – `run-apex-tests.sh` validates test class structure before deployment.

---

## Required Secrets

See `SECRETS_AND_CONFIG.md` for full details.

**DevTrial:** `SF_JWT_KEY_DEVTRIAL`, `SF_USERNAME_DEVTRIAL`, `SF_CLIENT_ID_DEVTRIAL`, `SF_INSTANCE_URL_DEVTRIAL`

**SIT Org:** `SF_JWT_KEY_SITORG`, `SF_USERNAME_SITORG`, `SF_CLIENT_ID_SITORG`, `SF_INSTANCE_URL_SITORG`

---

## GitHub Configuration

- **Branch protection:** Require PR approval for `CRM_DevTrial2` and `CRM_SITTrial`
- **Actions:** Allow workflows to create PRs and push branches
