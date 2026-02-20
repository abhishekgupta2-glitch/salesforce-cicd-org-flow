# GitHub Secrets and Configuration Guide

This document lists all required secrets and GitHub configuration settings for the CI/CD workflows.

## Required GitHub Secrets

### Salesforce Org Authentication Secrets

#### CRM_DevTrial Org
- **`SF_JWT_KEY_DEVTRIAL`** (Required)
  - Description: Private key for JWT authentication to CRM_DevTrial org
  - Format: RSA private key (including BEGIN/END lines)
  - How to get: Export from your JWT certificate file

- **`SF_USERNAME_DEVTRIAL`** (Required)
  - Description: Salesforce username for CRM_DevTrial org
  - Format: Email address (e.g., `user@example.com`)

- **`SF_CLIENT_ID_DEVTRIAL`** (Required)
  - Description: Connected App Consumer Key for CRM_DevTrial org
  - Format: OAuth Consumer Key (starts with specific prefix)

- **`SF_INSTANCE_URL_DEVTRIAL`** (Required)
  - Description: Salesforce instance URL for CRM_DevTrial org
  - Format: `https://login.salesforce.com` or `https://test.salesforce.com` or custom domain

#### CRM_SITOrg Secrets
- **`SF_JWT_KEY_SITORG`** (Required)
  - Description: Private key for JWT authentication to CRM_SITOrg
  - Format: RSA private key (including BEGIN/END lines)

- **`SF_USERNAME_SITORG`** (Required)
  - Description: Salesforce username for CRM_SITOrg
  - Format: Email address

- **`SF_CLIENT_ID_SITORG`** (Required)
  - Description: Connected App Consumer Key for CRM_SITOrg
  - Format: OAuth Consumer Key

- **`SF_INSTANCE_URL_SITORG`** (Required)
  - Description: Salesforce instance URL for CRM_SITOrg
  - Format: `https://login.salesforce.com` or `https://test.salesforce.com` or custom domain

### Email Notification Secrets (Optional)

- **`EMAIL_API_URL`** (Optional)
  - Description: API endpoint URL for sending emails
  - Examples:
    - SendGrid: `https://api.sendgrid.com/v3/mail/send`
    - AWS SES: Your SES API endpoint
    - Custom email service endpoint

- **`EMAIL_API_KEY`** (Optional)
  - Description: API key/token for email service authentication
  - Format: API key string

- **`DEPLOYMENT_NOTIFICATION_EMAIL`** (Optional)
  - Description: Email address(es) to receive deployment notifications
  - Format: Single email or comma-separated list
  - Example: `devops@company.com` or `devops@company.com,team@company.com`

### GitHub Token (Auto-provided)

- **`GITHUB_TOKEN`** (Auto-provided)
  - Description: Automatically provided by GitHub Actions
  - Permissions: Automatically configured in workflows
  - No action needed

## GitHub Configuration Settings

### 1. Branch Protection Rules

#### For `CRM_DevTrial2` Branch
1. Go to: **Repository Settings** → **Branches** → **Add rule**
2. Branch name pattern: `CRM_DevTrial2`
3. Enable:
   - ✅ **Require pull request reviews before merging**
     - Required number of approvals: **1**
     - Dismiss stale pull request approvals when new commits are pushed: **Enabled**
   - ✅ **Require status checks to pass before merging** (Optional but recommended)
     - Select required status checks:
       - `precheck-and-promote`
       - `check-approval-and-deploy`
   - ✅ **Require conversation resolution before merging** (Optional)
   - ✅ **Do not allow bypassing the above settings** (Recommended)

#### For `CRM_SITTrial` Branch
1. Go to: **Repository Settings** → **Branches** → **Add rule**
2. Branch name pattern: `CRM_SITTrial`
3. Enable:
   - ✅ **Require pull request reviews before merging**
     - Required number of approvals: **1**
   - ✅ **Require status checks to pass before merging** (Optional)
     - Select: `promote-to-sit`
   - ✅ **Do not allow bypassing the above settings** (Recommended)

### 2. Repository Settings

#### Actions Permissions
1. Go to: **Repository Settings** → **Actions** → **General**
2. Ensure:
   - ✅ **Allow all actions and reusable workflows**
   - ✅ **Allow GitHub Actions to create and approve pull requests**
   - ✅ **Allow actions to read and write permissions** (if needed)

#### Workflow Permissions
- Workflows automatically request necessary permissions
- No manual configuration needed

### 3. Connected App Configuration in Salesforce

For each Salesforce org (CRM_DevTrial and CRM_SITOrg):

1. **Create Connected App:**
   - Setup → App Manager → New Connected App
   - Enable OAuth Settings
   - Callback URL: `https://login.salesforce.com/services/oauth2/success`
   - Selected OAuth Scopes:
     - ✅ **Perform requests on your behalf at any time (refresh_token, offline_access)**
     - ✅ **Access and manage your data (api)**
     - ✅ **Access your basic information (id, profile, email, address, phone)**

2. **Generate Certificate:**
   - Use Certificate and Key Management
   - Create a self-signed certificate
   - Download certificate and private key
   - Upload certificate to Connected App

3. **Pre-authorize Connected App:**
   - In Connected App settings, go to **Manage** → **Edit Policies**
   - Set **Permitted Users** to **Admin approved users are pre-authorized**
   - Go to **Manage** → **Pre-authorize** → Add the user (username from `SF_USERNAME_*` secret)

4. **Get Consumer Key:**
   - Copy the Consumer Key → Use as `SF_CLIENT_ID_*` secret

## Workflow Summary

### Flow 1: Feature Branch → DevTrial
1. Push to `feature/*` branch
2. Workflow: `validate-pr-against-sit.yml`
   - Creates `promo/*` branch
   - Runs PMD checks
   - Runs Apex tests
   - Creates PR to `CRM_DevTrial2`
3. PR approved → Merge PR
4. Workflow: `deploy-after-pr-approval.yml`
   - Deploys to `CRM_DevTrial` org
   - Runs tests
   - Sends email notification

### Flow 2: DevTrial → SIT
1. PR merged to `CRM_DevTrial2`
2. Workflow: `sit-promotion-and-deployment.yml` (Job 1: `promote-to-sit`)
   - Creates `sit-promo/*` branch from `CRM_SITTrial`
   - Merges changes from `CRM_DevTrial2`
   - Runs PMD checks
   - Runs Apex tests
   - Creates PR to `CRM_SITTrial`
3. PR approved → Merge PR
4. Workflow: `sit-promotion-and-deployment.yml` (Job 2: `deploy-to-sit-org`)
   - Deploys to `CRM_SITOrg`
   - Runs tests
   - Sends email notification

## Email Service Configuration Examples

### Option 1: SendGrid
```bash
# Set secrets:
EMAIL_API_URL=https://api.sendgrid.com/v3/mail/send
EMAIL_API_KEY=<your-sendgrid-api-key>
DEPLOYMENT_NOTIFICATION_EMAIL=devops@company.com
```

### Option 2: AWS SES
```bash
# Set secrets:
EMAIL_API_URL=https://email.us-east-1.amazonaws.com/
EMAIL_API_KEY=<aws-access-key>
DEPLOYMENT_NOTIFICATION_EMAIL=devops@company.com
```

### Option 3: Custom Email Service
```bash
# Set secrets:
EMAIL_API_URL=https://your-email-service.com/api/send
EMAIL_API_KEY=<your-api-key>
DEPLOYMENT_NOTIFICATION_EMAIL=devops@company.com
```

## Troubleshooting

### JWT Authentication Fails
- Verify private key includes BEGIN/END lines
- Check username matches Connected App pre-authorized user
- Verify Consumer Key (Client ID) is correct
- Ensure instance URL matches org type (production vs sandbox)

### Email Not Sending
- Check if email service secrets are configured
- Verify email API endpoint is correct
- Check API key permissions
- Review workflow logs for email service errors

### Branch Protection Issues
- Ensure branch protection rules are configured
- Verify required status checks are passing
- Check if PR has required approvals

## Quick Setup Checklist

- [ ] Create Connected Apps in Salesforce orgs
- [ ] Generate and upload certificates
- [ ] Pre-authorize users in Connected Apps
- [ ] Add all required secrets to GitHub repository
- [ ] Configure branch protection rules
- [ ] (Optional) Configure email notification service
- [ ] Test workflow with a feature branch push
