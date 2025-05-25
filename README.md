# Exploring IAM

This repository contains a comprehensive walkthrough of Google Cloud Identity and Access Management (IAM) concepts, demonstrating access control, service accounts, and role-based permissions.

## Video

https://youtu.be/czHgQRb4KFg

## 🎯 Project Overview

This lab explores fundamental IAM concepts in Google Cloud Platform, including:
- Implementing access control with multiple users
- Restricting access to specific features and resources
- Using Service Account User roles
- Managing permissions for Cloud Storage and Compute Engine

## 📋 Learning Objectives

By completing this lab, you will learn how to:
- Use IAM to implement access control
- Restrict access to specific features or resources
- Use the Service Account User role
- Grant and revoke permissions effectively
- Work with service accounts and VM instances

## 🛠 Prerequisites

- Google Cloud Platform account
- Basic understanding of cloud concepts
- Familiarity with command-line interfaces

## 📁 Repository Structure

```
├── README.md                 # This file
├── docs/
│   ├── setup-guide.md       # Detailed setup instructions
│   ├── troubleshooting.md   # Common issues and solutions
│   └── best-practices.md    # IAM best practices
├── scripts/
│   ├── setup.sh            # Automated setup script
│   └── cleanup.sh          # Resource cleanup script
└── examples/
    ├── iam-policies.json   # Example IAM policy configurations
    └── service-account.json # Service account configuration
```

## 🚀 Quick Start

### Task 1: Setup for Two Users

1. **Sign in as User 1**
   - Open Google Cloud Console in incognito mode
   - Use the provided Username 1 credentials
   - Navigate through the initial setup

2. **Add User 2**
   - Open another incognito tab
   - Navigate to `console.cloud.google.com`
   - Click user icon → "Add account"
   - Sign in with Username 2 credentials

### Task 2: Explore IAM Console

1. **Navigate to IAM**
   ```
   Navigation Menu → IAM & Admin → IAM
   ```

2. **Explore Roles**
   - Click "Grant Access" to view available roles
   - Note the different roles for each resource type
   - Observe User 2's current Viewer role limitations

### Task 3: Prepare Resources for Testing

1. **Create Cloud Storage Bucket**
   ```
   Navigation Menu → Cloud Storage → Buckets → +Create
   ```
   
   Configuration:
   - **Name**: Choose globally unique name
   - **Location type**: Multi-region
   - Upload a sample file and rename to `sample.txt`

2. **Verify Access**
   - Switch to User 2 tab
   - Confirm bucket visibility

### Task 4: Remove Project Access

1. **Remove User 2's Project Viewer Role**
   ```
   IAM & Admin → IAM → Select Username 2 → Remove Access
   ```

2. **Verify Access Loss**
   - User 2 can no longer access project resources
   - Error messages appear when trying to navigate

### Task 5: Grant Storage-Specific Access

1. **Add Storage Object Viewer Role**
   ```
   IAM & Admin → IAM → Grant Access
   New principals: [Username 2]
   Role: Cloud Storage → Storage Object Viewer
   ```

2. **Test Limited Access**
   ```bash
   # In Cloud Shell as User 2
   gcloud storage ls gs://[YOUR_BUCKET_NAME]
   ```

### Task 6: Service Account Setup

1. **Create Service Account**
   ```
   IAM & Admin → Service Accounts → +CREATE SERVICE ACCOUNT
   Name: read-bucket-objects
   Role: Cloud Storage → Storage Object Viewer
   ```

2. **Grant Service Account User Role**
   ```
   Service Account → Manage permissions → Grant Access
   New principals: altostrat.com
   Role: Service Accounts → Service Account User
   ```

3. **Grant Compute Engine Access**
   ```
   IAM & Admin → IAM → Grant Access
   New principals: altostrat.com
   Role: Compute Engine → Compute Instance Admin (v1)
   ```

4. **Create VM with Service Account**
   ```
   Compute Engine → VM instances → CREATE INSTANCE
   Name: demoiam
   Machine Type: e2-micro
   Service account: read-bucket-objects
   Storage access: Read Write
   ```

### Task 7: Test Service Account Permissions

1. **SSH to VM**
   ```bash
   # Try to list instances (will fail due to insufficient permissions)
   gcloud compute instances list
   
   # Download file from bucket (will succeed)
   gcloud storage cp gs://[YOUR_BUCKET_NAME]/sample.txt .
   
   # Rename file
   mv sample.txt sample2.txt
   
   # Try to upload (will fail initially)
   gcloud storage cp sample2.txt gs://[YOUR_BUCKET_NAME]
   ```

2. **Fix Permissions**
   - Change service account role to "Storage Object Creator"
   - Retry upload command (will now succeed)

## 🔍 Key Concepts Demonstrated

### 1. **Principle of Least Privilege**
- Users receive only the minimum permissions necessary
- Granular control over resource access

### 2. **Role-Based Access Control (RBAC)**
- Predefined roles for common use cases
- Custom roles for specific requirements

### 3. **Service Account Authentication**
- Applications authenticate using service accounts
- VM instances can assume service account permissions

### 4. **Permission Inheritance**
- Project-level permissions vs. resource-specific permissions
- How different permission levels interact

## 🛡️ Security Best Practices

1. **Regular Access Reviews**
   - Periodically audit user permissions
   - Remove unnecessary access promptly

2. **Service Account Management**
   - Use dedicated service accounts for applications
   - Rotate service account keys regularly

3. **Monitoring and Logging**
   - Enable Cloud Audit Logs
   - Monitor IAM policy changes

4. **Separation of Duties**
   - Avoid overly broad permissions
   - Use multiple accounts for different functions

## 🔧 Troubleshooting

### Common Issues

**Access Denied Errors**
```
Error: 403 Forbidden
Solution: Verify user has appropriate role assigned
```

**Service Account Issues**
```
Error: insufficient authentication scopes
Solution: Check VM's service account and access scopes
```

**Bucket Access Problems**
```
Error: storage.objects.create access denied
Solution: Ensure Storage Object Creator role is assigned
```

## 📚 Additional Resources

- [Google Cloud IAM Documentation](https://cloud.google.com/iam/docs)
- [IAM Best Practices](https://cloud.google.com/iam/docs/using-iam-securely)
- [Service Account Best Practices](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you encounter issues or have questions:
1. Check the troubleshooting section
2. Review Google Cloud documentation
3. Open an issue in this repository

---

**Note**: This lab uses temporary Google Cloud credentials provided by Qwiklabs. Ensure you follow the provided instructions and don't use personal Google Cloud accounts to avoid unexpected charges.
