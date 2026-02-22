# Workflow Trigger Troubleshooting Guide

## Issue: Feature Branch Push Not Triggering Workflow

### Quick Fixes:

1. **Verify Workflow File is in Main Branch**
   ```bash
   git checkout main
   git pull origin main
   ls -la .github/workflows/validate-pr-against-sit.yml
   ```

2. **Commit and Push Workflow File to Main**
   ```bash
   git checkout main
   git add .github/workflows/validate-pr-against-sit.yml
   git commit -m "Fix workflow trigger pattern for feature branches"
   git push origin main
   ```

3. **Check GitHub Actions Settings**
   - Go to: Repository → Settings → Actions → General
   - Ensure "Allow all actions and reusable workflows" is enabled
   - Check "Workflow permissions" settings

4. **Verify Branch Pattern**
   - Current pattern: `feature/*` and `feature/**`
   - Your branches should match: `feature/121`, `feature/122`, etc.
   - Pattern `feature/*` matches single-level branches
   - Pattern `feature/**` matches nested branches

### Common Issues:

1. **Workflow File Not in Default Branch**
   - GitHub Actions only recognizes workflows in the default branch (usually `main`)
   - Workflow files in feature branches won't trigger workflows

2. **GitHub Actions Disabled**
   - Check repository settings → Actions → General
   - Ensure Actions are enabled

3. **Branch Pattern Mismatch**
   - If your branch is `feature-121` instead of `feature/121`, the pattern won't match
   - Update pattern to match your branch naming convention

4. **Paths Ignore Filtering Everything**
   - If you only push `.md` files, the workflow won't trigger due to `paths-ignore`
   - Make sure you're pushing code files, not just documentation

### Testing:

1. **Push a Test Commit to Feature Branch**
   ```bash
   git checkout feature/121  # or your feature branch
   echo "test" >> test.txt
   git add test.txt
   git commit -m "Test workflow trigger"
   git push origin feature/121
   ```

2. **Check GitHub Actions Tab**
   - Go to: Repository → Actions tab
   - Look for "Feature Branch Validation and Promotion" workflow
   - Should show as "queued" or "running"

3. **Check Workflow Runs**
   - If workflow doesn't appear, check:
     - Repository Settings → Actions → General
     - Workflow file syntax (no YAML errors)
     - Branch pattern matches your branch name

### Updated Trigger Pattern:

The workflow now uses:
```yaml
on:
  push:
    branches:
      - 'feature/*'      # Matches feature/121, feature/122, etc.
      - 'feature/**'     # Matches nested branches if needed
```

This should trigger on any push to branches matching `feature/*` pattern.
