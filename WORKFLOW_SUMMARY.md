# CI/CD Workflow Summary

## Overview

This repository implements a multi-stage CI/CD pipeline for Salesforce deployments across three environments:
1. **DevTrial** - Development/Testing environment
2. **SIT** - System Integration Testing environment

## Workflow Files

### 1. `validate-pr-against-sit.yml`
**Purpose:** Feature branch validation and promotion to DevTrial

**Triggers:** Push to `feature/*` branches

**Steps:**
1. Checkout feature branch
2. Install Salesforce CLI and tools
3. Create/update promotional branch (`promo/*`) from `CRM_DevTrial2`
4. Merge feature branch into promotional branch
5. Generate delta packages
6. Run PMD checks (non-blocking)
7. Run Apex tests against promotional branch code
8. Push promotional branch
9. Create/update PR to `CRM_DevTrial2`

**Key Features:**
- Handles existing promotional branches gracefully
- Uses `force-with-lease` for safe git pushes
- Updates existing PRs instead of creating duplicates
- Non-blocking PMD checks (shows violations but doesn't fail)

---

### 2. `deploy-after-pr-approval.yml`
**Purpose:** Deploy to CRM_DevTrial org after PR merge

**Triggers:** PR merged to `CRM_DevTrial2` (from `promo/*` branches)

**Steps:**
1. Checkout merge commit
2. Verify PR merge status
3. Generate delta packages
4. Authorize CRM_DevTrial org (JWT)
5. Deploy delta changes
6. Run Apex tests and check coverage (>75% required)
7. Comment on PR with deployment status
8. Send email notification (if configured)

**Key Features:**
- Only triggers on PR merge (not approval)
- Deploys only merged changes
- Validates org-wide coverage
- Sends email notifications

---

### 3. `sit-promotion-and-deployment.yml`
**Purpose:** Promote to SIT environment and deploy to CRM_SITOrg

**Two Jobs:**

#### Job 1: `promote-to-sit`
**Triggers:** PR merged to `CRM_DevTrial2` (from `promo/*` branches)

**Steps:**
1. Checkout merge commit from CRM_DevTrial2
2. Create SIT promotional branch (`sit-promo/*`) from `CRM_SITTrial`
3. Merge CRM_DevTrial2 changes into SIT promotional branch
4. Generate delta packages
5. Run PMD checks
6. Run Apex tests
7. Push SIT promotional branch
8. Create/update PR to `CRM_SITTrial`

#### Job 2: `deploy-to-sit-org`
**Triggers:** PR merged to `CRM_SITTrial` (from `sit-promo/*` branches)

**Steps:**
1. Checkout merge commit
2. Verify PR merge status
3. Generate delta packages
4. Authorize CRM_SITOrg (JWT)
5. Deploy delta changes
6. Run Apex tests and check coverage (>75% required)
7. Send email notification with full summary
8. Comment on PR

**Key Features:**
- Cascading deployment: DevTrial → SIT
- Separate validation before SIT deployment
- Email notifications with deployment summary
- Includes who merged the PR

---

## Complete Flow Diagram

```
Feature Branch (feature/XXX)
    ↓
[validate-pr-against-sit.yml]
    ├─ Create promo/XXX branch
    ├─ Run PMD checks
    ├─ Run Apex tests
    └─ Create PR to CRM_DevTrial2
         ↓
    PR Approved & Merged
         ↓
[deploy-after-pr-approval.yml]
    ├─ Deploy to CRM_DevTrial org
    ├─ Run tests
    └─ Send email notification
         ↓
[sit-promotion-and-deployment.yml - Job 1]
    ├─ Create sit-promo/XXX branch
    ├─ Merge CRM_DevTrial2 changes
    ├─ Run PMD checks
    ├─ Run Apex tests
    └─ Create PR to CRM_SITTrial
         ↓
    PR Approved & Merged
         ↓
[sit-promotion-and-deployment.yml - Job 2]
    ├─ Deploy to CRM_SITOrg
    ├─ Run tests
    └─ Send email notification (with merge details)
```

## Branch Naming Convention

- **Feature branches:** `feature/XXX` or `feature-XXX`
- **DevTrial promotional branches:** `promo/XXX`
- **SIT promotional branches:** `sit-promo/XXX`
- **Base branches:** `CRM_DevTrial2`, `CRM_SITTrial`

## Key Improvements Made

1. ✅ **Fixed Git Push Issues**
   - Uses `force-with-lease` for safe updates
   - Handles existing branches gracefully
   - Fetches remote before pushing

2. ✅ **PR Update Instead of Duplicate**
   - Checks for existing PRs
   - Updates existing PR instead of creating new one
   - Prevents multiple PRs for same feature

3. ✅ **SIT Environment Flow**
   - Automatic promotion from DevTrial to SIT
   - Separate validation before SIT deployment
   - Cascading deployment pattern

4. ✅ **Email Notifications**
   - Deployment summaries
   - Includes who merged PR
   - Configurable email service

5. ✅ **Non-blocking PMD Checks**
   - Always runs PMD
   - Shows violations in summary
   - Doesn't fail workflow on violations

## Required Secrets

See `SECRETS_AND_CONFIG.md` for complete list.

**Quick Summary:**
- `SF_JWT_KEY_DEVTRIAL`, `SF_USERNAME_DEVTRIAL`, `SF_CLIENT_ID_DEVTRIAL`, `SF_INSTANCE_URL_DEVTRIAL`
- `SF_JWT_KEY_SITORG`, `SF_USERNAME_SITORG`, `SF_CLIENT_ID_SITORG`, `SF_INSTANCE_URL_SITORG`
- `EMAIL_API_URL`, `EMAIL_API_KEY`, `DEPLOYMENT_NOTIFICATION_EMAIL` (optional)

## GitHub Configuration

1. **Branch Protection Rules:**
   - `CRM_DevTrial2`: Require 1 approval
   - `CRM_SITTrial`: Require 1 approval

2. **Repository Settings:**
   - Allow all actions
   - Allow GitHub Actions to create PRs

See `SECRETS_AND_CONFIG.md` for detailed setup instructions.
