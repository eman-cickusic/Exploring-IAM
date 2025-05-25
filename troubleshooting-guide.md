# Troubleshooting Guide

## Common Issues and Solutions

### Authentication Problems

#### Issue: "Authentication failed" or "Invalid credentials"
**Symptoms:**
- Cannot sign in to Google Cloud Console
- Error messages about invalid username/password
- Redirected back to login page

**Solutions:**
1. **Verify Credentials**
   ```
   ✓ Use exact username from Qwiklabs Connection Details
   ✓ Use exact password from Qwiklabs Connection Details  
   ✓ Copy-paste credentials to avoid typos
   ```

2. **Browser Issues**
   ```
   ✓ Use incognito/private browsing mode
   ✓ Clear browser cache and cookies
   ✓ Try different browser
   ✓ Disable browser extensions
   ```

3. **Account Conflicts**
   ```
   ✓ Sign out of personal Google accounts
   ✓ Use "Use Another Account" option
   ✓ Don't mix lab and personal accounts
   ```

#### Issue: "Account deleted" or "User 2 disappeared"
**Cause:** Signing out of User 1 while User 2 is active

**Solution:**
- Keep User 1 signed in throughout the lab
- Use separate browser tabs, not separate windows
- If User 2 gets deleted, re-add the account

### Permission Errors

#### Issue: "Error 403: Forbidden" or "Access Denied"
**Common Scenarios:**

**Scenario 1: User 2 cannot access project resources**
```bash
# Error when User 2 tries to access resources
Error: User does not have permission to access project
```
**Solution:**
- Verify User 2 has appropriate project-level role
- Check IAM policy bindings in IAM & Admin console

**Scenario 2: Cannot upload to Cloud Storage**
```bash
# Error when trying to upload files
AccessDeniedException: 403 Caller does not have storage.objects.create access
```
**Solution:**
- Grant `Storage Object Creator` role
- Verify service account has correct permissions

**Scenario 3: Cannot list compute instances**
```bash
# Error from service account on VM
WARNING: Some requests did not succeed.
- Request had insufficient authentication scopes.
```
**Solution:**
- Service account needs `Compute Engine` permissions
- VM needs appropriate access scopes

### Resource Issues

#### Issue: "Bucket not found" or "Bucket already exists"
**For "Bucket not found":**
1. Verify bucket name spelling
2. Check if bucket was created in correct project
3. Ensure you have read permissions

**For "Bucket already exists":**
1. Bucket names are globally unique
2. Choose a different bucket name
3. Add timestamp or random string to make unique

```bash
# Example: Add timestamp to bucket name
BUCKET_NAME="my-iam-lab-bucket-$(date +%s)"
```

#### Issue: "VM instance not found" or "Zone not available"
**Solutions:**
1. **Check Zone Availability**
   ```bash
   gcloud compute zones list --filter="region:us-central1"
   ```

2. **Verify Instance Name**
   ```bash
   gcloud compute instances list --filter="name:demoiam"
   ```

3. **Use Correct Zone**
   ```bash
   gcloud config set compute/zone us-central1-a
   ```

### Service Account Issues

#### Issue: "Service account does not exist"
**Symptoms:**
- Cannot attach service account to VM
- Service account not listed in dropdown

**Solutions:**
1. **Verify Service Account Creation**
   ```bash
   gcloud iam service-accounts list
   ```

2. **Check Service Account Email Format**
   ```
   Correct: read-bucket-objects@PROJECT_ID.iam.gserviceaccount.com
   Incorrect: read-bucket-objects@PROJECT_ID.com
   ```

3. **Recreate Service Account**
   ```bash
   gcloud iam service-accounts create read-bucket-objects \
     --display-name="Read Bucket Objects"
   ```

#### Issue: "Insufficient authentication scopes"
**Cause:** VM created with limited OAuth scopes

**Solution:**
1. **Check Current VM Scopes**
   ```bash
   gcloud compute instances describe demoiam --zone=ZONE \
     --format="value(serviceAccounts[0].scopes)"
   ```

2. **Recreate VM with Correct Scopes**
   ```bash
   gcloud compute instances create demoiam \
     --service-account=SERVICE_ACCOUNT_EMAIL \
     --scopes=storage-rw,compute-ro
   ```

### IAM Policy Issues

#### Issue: "Cannot modify IAM policies"
**Symptoms:**
- Pencil icon is grayed out
- "Edit" option not available
- Permission denied when trying to modify roles

**Solutions:**
1. **Check User Permissions**
   - User must have `Project IAM Admin` or `Owner` role
   - User 2 (Viewer) cannot modify IAM policies

2. **Verify Current Role**
   ```bash
   gcloud projects get-iam-policy PROJECT_ID \
     --flatten="bindings[].members" \
     --format="table(bindings.role,bindings.members)"
   ```

#### Issue: "Policy binding not taking effect"
**Symptoms:**
- Added role but permissions still denied
- Changes not reflected immediately

**Solutions:**
1. **Wait for Propagation**
   - IAM changes can take up to 60 seconds
   - Try the operation again after waiting

2. **Verify Policy Application**
   ```bash
   gcloud projects get-iam-policy PROJECT_ID \
     --filter="bindings.members:USER_EMAIL"
   ```

3. **Check Resource-Level Permissions**
   - Some resources have their own IAM policies
   - Project-level roles may not grant resource access

### Network and Connectivity Issues

#### Issue: "Cannot connect to VM via SSH"
**Solutions:**
1. **Check Firewall Rules**
   ```bash
   gcloud compute firewall-rules list --filter="name:default-allow-ssh"
   ```

2. **Verify VM Status**
   ```bash
   gcloud compute instances describe demoiam --zone=ZONE \
     --format="value(status)"
   ```

3. **Use Browser SSH**
   - Click "SSH" button in Cloud Console
   - Browser-based SSH bypasses local network issues

### Command Line Issues

#### Issue: "gcloud command not found"
**Solutions:**
1. **Install Google Cloud SDK**
   - Download from cloud.google.com/sdk
   - Follow installation instructions for your OS

2. **Update PATH**
   ```bash
   export PATH=$PATH:/path/to/google-cloud-sdk/bin
   ```

#### Issue: "Project not set" or "Authentication required"
**Solutions:**
1. **Authenticate gcloud**
   ```bash
   gcloud auth login
   ```

2. **Set Project**
   ```bash
   gcloud config set project PROJECT_ID
   ```

3. **Verify Configuration**
   ```bash
   gcloud config list
   ```

## Diagnostic Commands

### Quick Health Check
```bash
# Check authentication
gcloud auth list

# Check current project
gcloud config get-value project

# Check IAM permissions
gcloud projects get-iam-policy $(gcloud config get-value project)

# List service accounts
gcloud iam service-accounts list

# List compute instances
gcloud compute instances list

# List storage buckets
gcloud storage buckets list
```

### Detailed Diagnostics
```bash
# Check service account details
gcloud iam service-accounts describe SERVICE_ACCOUNT_EMAIL

# Check VM service account
gcloud compute instances describe VM_NAME --zone=ZONE \
  --format="value(serviceAccounts[0].email)"

# Test storage access
gcloud storage ls gs://BUCKET_NAME

# Check role permissions
gcloud iam roles describe ROLE_NAME
```

## Best Practices for Avoiding Issues

### Before Starting
1. **Environment Preparation**
   - Use incognito/private browsing
   - Close other Google accounts
   - Have lab credentials ready

2. **Resource Naming**
   - Use descriptive, unique names
   - Include timestamps for global resources
   - Follow naming conventions

### During Lab Execution
1. **Verification Steps**
   - Verify each step before proceeding
   - Check resource creation success
   - Test permissions after each change

2. **Error Handling**
   - Read error messages carefully
   - Check spelling and syntax
   - Verify resource existence

### After Completion
1. **Resource Cleanup**
   - Delete created resources
   - Remove IAM policy bindings
   - Clean up local files

2. **Documentation**
   - Note any issues encountered
   - Document workarounds used
   - Save configuration details

## Getting Help

### Internal Resources
1. **Google Cloud Documentation**
   - IAM Overview: cloud.google.com/iam/docs
   - Troubleshooting Guide: cloud.google.com/iam/docs/troubleshooting

2. **Support Channels**
   - Google Cloud Support Console
   - Community Forums
   - Stack Overflow (google-cloud-platform tag)

### Lab-Specific Help
1. **Qwiklabs Support**
   - Use "Help" button in lab interface
   - Check lab discussion forums
   - Contact Qwiklabs support team

2. **Self-Diagnosis**
   - Review error messages carefully
   - Check prerequisite steps
   - Verify account permissions

Remember: Most IAM issues are related to missing permissions or incorrect role assignments. Always start by checking the IAM policy bindings and service account configurations.