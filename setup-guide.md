# Detailed Setup Guide

## Environment Setup

### Prerequisites Checklist
- [ ] Google Cloud Console access
- [ ] Two user accounts provided by Qwiklabs
- [ ] Incognito/Private browsing mode enabled
- [ ] Stable internet connection

### Initial Configuration

#### Step 1: Primary User Setup
1. **Launch Lab Environment**
   - Click "Start Lab" in Qwiklabs
   - Note the provided credentials
   - Click "Open Google Cloud Console"

2. **Sign In Process**
   ```
   Username: [From Lab Details Panel]
   Password: [From Lab Details Panel]
   ```

3. **Console Navigation**
   - Accept terms and conditions
   - Skip recovery options
   - Skip free trial signup

#### Step 2: Secondary User Setup
1. **Open Second Browser Tab**
   - Use same incognito window
   - Navigate to `console.cloud.google.com`

2. **Add Second Account**
   - Click user profile icon (top-right)
   - Select "Add account"
   - Sign in with Username 2

3. **Account Management**
   - Keep both accounts active
   - Switch between tabs as needed

## Resource Creation Guide

### Cloud Storage Bucket Setup

#### Bucket Configuration
```yaml
Name: [globally-unique-name]
Location Type: Multi-region
Default Storage Class: Standard
Access Control: Uniform
Public Access: Prevented
```

#### File Upload Process
1. Click "Upload" → "Upload file"
2. Select any local file
3. After upload, click "⋮" → "Rename"
4. Change name to `sample.txt`

### Service Account Configuration

#### Service Account Details
```yaml
Name: read-bucket-objects
Display Name: Read Bucket Objects
Description: Service account for bucket read operations
```

#### Role Assignment
```yaml
Primary Role: Storage Object Viewer
Additional Permissions: None initially
Grant Access To: altostrat.com (domain)
Domain Role: Service Account User
```

### VM Instance Setup

#### Instance Configuration
```yaml
Name: demoiam
Region: [Lab specified region]
Zone: [Lab specified zone]
Machine Family: General-purpose
Series: E2
Machine Type: e2-micro (2 vCPU, 1 GB memory)
Boot Disk: Debian GNU/Linux 12 (bookworm)
```

#### Service Account Settings
```yaml
Service Account: read-bucket-objects
Access Scopes: Set access for each API
Storage: Read Write
Compute Engine: Default
```

## Permission Management

### IAM Role Hierarchy

#### Project-Level Roles
- **Owner**: Full control over project
- **Editor**: Modify resources
- **Viewer**: Read-only access

#### Resource-Specific Roles
- **Storage Object Viewer**: Read objects
- **Storage Object Creator**: Create objects
- **Storage Object Admin**: Full object control

#### Service Account Roles
- **Service Account User**: Use service accounts
- **Service Account Admin**: Manage service accounts

### Permission Testing Matrix

| User | Project Access | Storage Access | Compute Access |
|------|---------------|----------------|----------------|
| User 1 | Owner | Full | Full |
| User 2 (Initial) | Viewer | Read via project | Read via project |
| User 2 (Modified) | None | Object Viewer | None |
| Service Account | None | Object Viewer/Creator | Instance access |

## Command Reference

### Cloud Shell Commands

#### Storage Operations
```bash
# List bucket contents
gcloud storage ls gs://[BUCKET_NAME]

# Copy file from bucket
gcloud storage cp gs://[BUCKET_NAME]/sample.txt .

# Copy file to bucket
gcloud storage cp sample2.txt gs://[BUCKET_NAME]
```

#### Compute Operations
```bash
# List compute instances
gcloud compute instances list

# SSH to instance
gcloud compute ssh demoiam --zone=[ZONE]
```

#### File Operations
```bash
# Rename file
mv sample.txt sample2.txt

# View file contents
cat sample.txt

# List directory contents
ls -la
```

## Verification Steps

### Access Verification Checklist

#### User 1 (Project Owner)
- [ ] Can access IAM console
- [ ] Can create/modify resources
- [ ] Can grant/revoke permissions
- [ ] Can create service accounts

#### User 2 (Limited Access)
- [ ] Initially has Viewer access
- [ ] Loses all access when role removed
- [ ] Gains specific storage access
- [ ] Cannot access other resources

#### Service Account
- [ ] Can read from storage bucket
- [ ] Cannot list compute instances
- [ ] Can write to bucket (after role update)
- [ ] Functions correctly on VM

### Testing Scenarios

#### Scenario 1: Full Access Test
```bash
# As User 1, verify full project access
gcloud projects list
gcloud storage buckets list
gcloud compute instances list
```

#### Scenario 2: Limited Access Test
```bash
# As User 2, test storage-only access
gcloud storage ls gs://[BUCKET_NAME]  # Should work
gcloud compute instances list         # Should fail
```

#### Scenario 3: Service Account Test
```bash
# SSH to VM and test service account permissions
gcloud storage cp gs://[BUCKET_NAME]/sample.txt .  # Should work
gcloud compute instances list                       # Should fail
```

## Troubleshooting Common Issues

### Authentication Problems
```
Issue: "Authentication failed"
Solution: Verify correct credentials are used
Check: Username and password from lab details
```

### Permission Errors
```
Issue: "403 Forbidden" or "Access Denied"
Solution: Check IAM roles and permissions
Verify: User has appropriate role assigned
```

### Resource Not Found
```
Issue: "Bucket not found" or "Instance not found"
Solution: Verify resource names and regions
Check: Bucket name is globally unique
```

### Service Account Issues
```
Issue: "Insufficient authentication scopes"
Solution: Check VM service account configuration
Verify: Correct service account is attached
```

## Best Practices

### Security Considerations
1. **Principle of Least Privilege**
   - Grant minimum necessary permissions
   - Regularly review and audit access

2. **Account Management**
   - Keep accounts separate
   - Don't mix personal and lab accounts

3. **Resource Cleanup**
   - Delete resources after lab completion
   - Avoid unexpected charges

### Operational Guidelines
1. **Documentation**
   - Record bucket names and configurations
   - Note any custom modifications

2. **Testing**
   - Verify each permission change
   - Test from different user perspectives

3. **Monitoring**
   - Check audit logs for access patterns
   - Monitor for unauthorized access attempts