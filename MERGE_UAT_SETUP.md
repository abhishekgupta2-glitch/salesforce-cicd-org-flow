# Merge and Deploy to UAT - Setup Guide

## Overview

The **Merge and Deploy to UAT** workflow lets you merge one or more feature branches into a UAT branch with a single button click from GitHub Actions.

## How to Use

1. Go to **Actions** tab in your GitHub repository
2. Select **"Merge and Deploy to UAT"** from the workflow list
3. Click **"Run workflow"** (dropdown on the right)
4. Fill in the inputs (or use defaults from secrets):
   - **Source branch(es)**: Single branch or comma-separated list (e.g. `feature/101,feature/102,feature/103`)
   - **Destination branch**: Target branch (e.g. `UAT`, `CRM_UAT`)
   - **Deploy to UAT org**: Check to deploy to Salesforce UAT org after merge
5. Click **"Run workflow"** (green button)

## Default Values: Use Variables (Recommended)

**Variables** are easier to add than secrets and work for non-sensitive data like branch names.

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click the **Variables** tab
3. Click **New repository variable**
4. Add:

| Variable | Description | Example |
|----------|-------------|---------|
| `MERGE_UAT_SOURCE` | Default source branch(es) - comma-separated for multiple | `feature/101,feature/102` |
| `MERGE_UAT_DESTINATION` | Default destination branch | `UAT` or `CRM_UAT` |

**If Variables fail:** You can also use Secrets (same names). The workflow checks Variables first, then Secrets.

### Optional (for deployment to UAT org)

| Secret | Description |
|--------|-------------|
| `SF_JWT_KEY_UAT` | JWT private key for UAT org |
| `SF_USERNAME_UAT` | UAT org username |
| `SF_CLIENT_ID_UAT` | Connected App consumer key |
| `SF_INSTANCE_URL_UAT` | UAT org instance URL |

## Behavior

- **Inputs override secrets**: If you fill in source/destination when running, they override the secret defaults
- **Multiple sources**: Merge order is left-to-right; each branch is merged into the destination sequentially
- **Merge conflicts**: Workflow fails with clear error; resolve conflicts manually and re-run
- **Deployment**: Enable via checkbox when running; requires UAT org JWT secrets

## Example

**Merge 3 feature branches to UAT:**
- Source: `feature/101,feature/102,feature/103`
- Destination: `UAT`

Result: `feature/101` → `feature/102` → `feature/103` are merged into `UAT` in that order, then pushed.
