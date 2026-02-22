# Troubleshooting: CRM_SITOrg JWT Authentication Error

## Error: "invalid client credentials"

This error occurs when the Salesforce CLI cannot authenticate using JWT. Here are the most common causes and solutions:

## ✅ Checklist: Verify GitHub Secrets

Ensure these secrets are configured in your GitHub repository:

1. **`SF_JWT_KEY_SITORG`** - Private key file content
2. **`SF_USERNAME_SITORG`** - Salesforce username (email)
3. **`SF_CLIENT_ID_SITORG`** - Connected App Consumer Key
4. **`SF_INSTANCE_URL_SITORG`** - Instance URL

### How to Check Secrets:
1. Go to: **Repository Settings** → **Secrets and variables** → **Actions**
2. Verify all 4 secrets exist for CRM_SITOrg
3. Check that secret names match exactly (case-sensitive)

---

## 🔍 Common Issues and Solutions

### Issue 1: Secrets Not Created
**Symptom:** Workflow fails immediately with "invalid client credentials"

**Solution:**
- Create all 4 secrets in GitHub repository settings
- Ensure secret names match exactly:
  - `SF_JWT_KEY_SITORG`
  - `SF_USERNAME_SITORG`
  - `SF_CLIENT_ID_SITORG`
  - `SF_INSTANCE_URL_SITORG`

---

### Issue 2: Incorrect Private Key Format
**Symptom:** JWT authentication fails even with correct credentials

**Solution:**
The private key must include the BEGIN and END lines:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
(multiple lines of base64 encoded key)
...
-----END RSA PRIVATE KEY-----
```

**How to verify:**
1. Open the secret `SF_JWT_KEY_SITORG` in GitHub
2. Ensure it starts with `-----BEGIN RSA PRIVATE KEY-----`
3. Ensure it ends with `-----END RSA PRIVATE KEY-----`
4. Ensure there are no extra spaces or characters before/after

**Common mistakes:**
- ❌ Missing BEGIN/END lines
- ❌ Extra spaces or newlines
- ❌ Wrong key format (should be RSA PRIVATE KEY, not CERTIFICATE)

---

### Issue 3: Wrong Consumer Key (Client ID)
**Symptom:** "invalid client credentials" error

**Solution:**
1. Go to Salesforce Setup → App Manager → Your Connected App
2. Click on the Connected App name
3. Copy the **Consumer Key** (not Consumer Secret)
4. Update `SF_CLIENT_ID_SITORG` secret with this value

**Note:** Consumer Key typically looks like: `3MVG9...` (long alphanumeric string)

---

### Issue 4: Wrong Username
**Symptom:** Authentication fails even with correct key and client ID

**Solution:**
1. Verify the username matches exactly (case-sensitive)
2. Use the full email address (e.g., `user@company.com`)
3. Ensure this user exists in the CRM_SITOrg Salesforce org
4. Verify the user is active (not deactivated)

---

### Issue 5: Wrong Instance URL
**Symptom:** Connection timeout or authentication failure

**Solution:**
Use the correct instance URL based on your org type:

- **Production org:** `https://login.salesforce.com`
- **Sandbox org:** `https://test.salesforce.com`
- **Custom domain:** `https://yourdomain.my.salesforce.com`

**How to find your instance URL:**
1. Log into Salesforce CRM_SITOrg
2. Check the URL in your browser
3. Use the base URL (before `/lightning/` or `/setup/`)

---

### Issue 6: Connected App Not Configured Correctly
**Symptom:** "invalid client credentials" or "user hasn't approved this consumer"

**Solution:**

#### Step 1: Create/Verify Connected App
1. Go to Salesforce Setup → App Manager → New Connected App
2. Fill in:
   - **Connected App Name:** `GitHub Actions CI/CD`
   - **API Name:** `GitHub_Actions_CI_CD`
   - **Contact Email:** Your email
3. Enable OAuth Settings:
   - **Callback URL:** `https://login.salesforce.com/services/oauth2/success`
   - **Selected OAuth Scopes:**
     - ✅ **Perform requests on your behalf at any time (refresh_token, offline_access)**
     - ✅ **Access and manage your data (api)**
     - ✅ **Access your basic information (id, profile, email, address, phone)**
4. **Use digital signatures:** ✅ Enabled
   - Upload your certificate file (the public key, not private key)
5. Save

#### Step 2: Generate Certificate
1. Go to Setup → Certificate and Key Management
2. Click **Create Self-Signed Certificate**
3. Fill in:
   - **Label:** `GitHub Actions JWT`
   - **Unique Name:** `GitHub_Actions_JWT`
   - **Key Size:** 2048
4. Click **Save**
5. Download the certificate file (`.crt`)
6. Download the private key file (`.key`)

#### Step 3: Upload Certificate to Connected App
1. Go back to your Connected App
2. Under **API (Enable OAuth Settings)**, click **Choose File**
3. Upload the certificate file (`.crt` file, NOT the private key)
4. Save

#### Step 4: Pre-authorize User
1. In Connected App, click **Manage** → **Edit Policies**
2. Set **Permitted Users:** `Admin approved users are pre-authorized`
3. Save
4. Go to **Manage** → **Pre-authorize**
5. Click **Add** → Select the user (username from `SF_USERNAME_SITORG`)
6. Save

---

### Issue 7: Certificate/Key Mismatch
**Symptom:** Authentication fails even with correct configuration

**Solution:**
1. Ensure the certificate uploaded to Connected App matches the private key
2. They must be from the same certificate/key pair
3. If you generated a new certificate, upload the new certificate to Connected App
4. Update `SF_JWT_KEY_SITORG` secret with the new private key

**How to verify:**
- The certificate file (`.crt`) uploaded to Salesforce should match the private key (`.key`) in GitHub secret
- They were generated together when you created the self-signed certificate

---

### Issue 8: User Not Pre-authorized
**Symptom:** "user hasn't approved this consumer" error

**Solution:**
1. Go to Connected App → **Manage** → **Pre-authorize**
2. Ensure the user (from `SF_USERNAME_SITORG`) is listed
3. If not, add the user
4. Save

---

## 🔧 Step-by-Step Verification

### 1. Verify Secrets in GitHub
```bash
# Check if secrets exist (you'll need to check in GitHub UI)
Repository Settings → Secrets and variables → Actions
```

### 2. Test JWT Authentication Locally
```bash
# Create server.key file with private key
echo "YOUR_PRIVATE_KEY_CONTENT" > server.key

# Test authentication
sf org login jwt \
  --username "your-username@company.com" \
  --jwt-key-file server.key \
  --client-id "YOUR_CONSUMER_KEY" \
  --instance-url "https://test.salesforce.com" \
  --alias CRM_SITOrg

# If this works locally, the issue is with GitHub secrets
# If this fails locally, the issue is with Salesforce configuration
```

### 3. Verify Connected App Configuration
- [ ] Connected App exists
- [ ] OAuth enabled
- [ ] Certificate uploaded
- [ ] User pre-authorized
- [ ] Consumer Key copied correctly

---

## 📋 Quick Fix Checklist

1. ✅ All 4 secrets created in GitHub (`SF_JWT_KEY_SITORG`, `SF_USERNAME_SITORG`, `SF_CLIENT_ID_SITORG`, `SF_INSTANCE_URL_SITORG`)
2. ✅ Private key includes BEGIN/END lines
3. ✅ Consumer Key matches Connected App
4. ✅ Username matches pre-authorized user
5. ✅ Instance URL is correct (test.salesforce.com for sandbox, login.salesforce.com for production)
6. ✅ Certificate uploaded to Connected App
7. ✅ User is pre-authorized in Connected App
8. ✅ Certificate and private key are from the same pair

---

## 🆘 Still Not Working?

If you've verified all the above:

1. **Check workflow logs** for more detailed error messages
2. **Test authentication locally** using Salesforce CLI
3. **Verify org access** - ensure you can log into CRM_SITOrg manually
4. **Check Salesforce org status** - ensure org is not in maintenance mode
5. **Review Connected App policies** - ensure OAuth policies allow access

---

## 📞 Need Help?

Common error messages and their meanings:

- **"invalid client credentials"** → Wrong Consumer Key or certificate/key mismatch
- **"user hasn't approved this consumer"** → User not pre-authorized
- **"invalid_grant"** → Wrong username or instance URL
- **"Connection timeout"** → Wrong instance URL or network issue
