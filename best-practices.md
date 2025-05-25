# Google Cloud IAM Best Practices

## Core IAM Principles

### 1. Principle of Least Privilege
Grant users and services only the minimum permissions necessary to perform their tasks.

**Implementation:**
- Start with no permissions and add as needed
- Use predefined roles when possible
- Create custom roles for specific use cases
- Regular permission audits and cleanup

**Example:**
```bash
# Instead of granting Editor role (broad permissions)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:developer@company.com" \
  --role="roles/editor"

# Grant specific role for the task
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:developer@company.com" \
  --role="roles/storage.objectAdmin"
```

### 2. Defense in Depth
Use multiple layers of security controls rather than relying on a single mechanism.

**Layers:**
- **Identity**: Multi-factor authentication
- **Network**: VPC firewalls and private networks
- **Application**: Service-to-service authentication
- **Data**: Encryption at rest and in transit

### 3. Zero Trust Security Model
Never trust, always verify - authenticate and authorize every request.

**Implementation:**
- Use service accounts for application authentication
- Implement short-lived credentials
- Monitor and log all access attempts
- Regular security assessments

## User Management Best Practices

### Individual User Accounts

**Do:**
- Create individual accounts for each person
- Use corporate email addresses
- Enable 2-factor authentication
- Regularly review user access

**Don't:**
- Share user accounts between people
- Use generic accounts (admin@company.com)
- Keep unused accounts active
- Grant permanent broad permissions

### Group-Based Access Control

**Structure:**
```
Organization: company.com
├── Groups:
│   ├── developers@company.com
│   ├── data-analysts@company.com
│   ├── security-team@company.com
│   └── project-managers@company.com
└── Projects:
    ├── development-project
    ├── production-project
    └── analytics-project
```

**Benefits:**
- Easier permission management
- Consistent access patterns
- Simplified onboarding/offboarding
- Better audit trails

**Example Group Policy:**
```bash
# Grant role to group instead of individual users
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="group:developers@company.com" \
  --role="roles/compute.developer"
```

## Service Account Management

### Service Account Design Patterns

#### 1. One Service Account Per Application
```bash
# Create dedicated service accounts
gcloud iam service-accounts create web-frontend-sa \
  --display-name="Web Frontend Service Account"

gcloud iam service-accounts create data-processor-sa \
  --display-name="Data Processing Service Account"
```

#### 2. Environment-Specific Service Accounts
```bash
# Separate service accounts for each environment
gcloud iam service-accounts create app-dev-sa
gcloud iam service-accounts create app-staging-sa  
gcloud iam service-accounts create app-prod-sa
```

#### 3. Function-Specific Service Accounts
```bash
# Different service accounts for different functions
gcloud iam service-accounts create storage-reader-sa
gcloud iam service-accounts create database-writer-sa
gcloud iam service-accounts create log-shipper-sa
```

### Service Account Security

**Key Management:**
- Avoid downloading service account keys when possible
- Use short-lived credentials (Workload Identity)
- Rotate keys regularly if downloads are necessary
- Store keys securely (never in code repositories)

**Access Control:**
```bash
# Limit who can use service accounts
gcloud iam service-accounts add-iam-policy-binding \
  SA_EMAIL \
  --member="group:authorized-users@company.com" \
  --role="roles/iam.serviceAccountUser"
```

**Monitoring:**
```bash
# Enable audit logging for service account usage
gcloud logging sinks create service-account-audit \
  bigquery.googleapis.com/projects/PROJECT_ID/datasets/audit_logs \
  --log-filter='protoPayload.serviceName="iam.googleapis.com" AND protoPayload.methodName="SetIamPolicy"'
```

## Role Management Strategies

### Predefined vs Custom Roles

**Use Predefined Roles When:**
- Standard use cases
- Quick prototyping
- Learning/development environments
- Common administrative tasks

**Create Custom Roles When:**
- Specific permission combinations needed
- Compliance requirements
- Complex multi-service applications
- Fine-grained access control

### Custom Role Example
```bash
# Create custom role with specific permissions
gcloud iam roles create dataProcessorRole \
  --project=PROJECT_ID \
  --title="Data Processor" \
  --description="Custom role for data processing applications" \
  --permissions="storage.objects.get,storage.objects.list,bigquery.jobs.create"
```

### Role Hierarchy Strategy
```
Organization Level:
├── roles/owner (Emergency access only)
├── roles/iam.organizationAdmin (IAM administrators)
└── roles/resourcemanager.folderAdmin (Resource administrators)

Folder Level:
├── roles/editor (Development environments)
├── roles/viewer (Read-only access)
└── custom.dataScientist (Data analysis access)

Project Level:
├── roles/compute.admin (Infrastructure team)
├── roles/storage.admin (Data team)
└── application.specific.roles (Application teams)
```

## Resource Organization

### Project Structure
```
Organization: company.com
├── Folders:
│   ├── Production/
│   │   ├── prod-web-app
│   │   ├── prod-database
│   │   └── prod-monitoring
│   ├── Development/
│   │   ├── dev-web-app
│   │   ├── dev-database
│   │   └── dev-sandbox
│   └── Shared/
│       ├── shared-networking
│       ├── shared-security
│       └── shared-logging
```

### Naming Conventions
```bash
# Consistent naming patterns
PROJECT_ID: [environment]-[application]-[team]-[sequence]
Examples:
- prod-webapp-frontend-001
- dev-analytics-datateam-001
- shared-network-platform-001

SERVICE_ACCOUNT: [function]-[environment]-sa
Examples:
- storage-reader-prod-sa
- compute-manager-dev-sa
- log-processor-shared-sa
```

## Monitoring and Auditing

### Essential Audit Logs
```bash
# Enable all audit log types
gcloud logging sinks create iam-audit-sink \
  bigquery.googleapis.com/projects/PROJECT_ID/datasets/security_logs \
  --log-filter='
    protoPayload.serviceName="iam.googleapis.com" OR
    protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
    protoPayload.serviceName="serviceusage.googleapis.com"
  '
```

### Key Metrics to Monitor
- **Failed authentication attempts**
- **Permission escalations**
- **Service account key downloads**
- **Unusual access patterns**
- **Policy modifications**

### Automated Monitoring Setup
```bash
# Create alerting policy for IAM changes
gcloud alpha monitoring policies create \
  --policy-from-file=iam-policy-changes-alert.yaml
```

## Access Review Process

### Monthly Reviews
- **User Access**: Review all user permissions
- **Service Accounts**: Audit service account usage
- **Unused Permissions**: Identify and remove unused roles
- **Cross-Project Access**: Review inter-project permissions

### Quarterly Reviews
- **Role Definitions**: Update custom roles
- **Group Memberships**: Verify group compositions
- **Emergency Access**: Review break-glass procedures
- **Compliance**: Ensure regulatory compliance

### Annual Reviews
- **Security Architecture**: Review overall IAM design
- **Business Alignment**: Ensure permissions match business needs
- **Technology Updates**: Adopt new IAM features
- **Disaster Recovery**: Test IAM recovery procedures

## Automation and Infrastructure as Code

### Terraform Example
```hcl
# Service account with minimal permissions
resource "google_service_account" "app_sa" {
  account_id   = "app-service-account"
  display_name = "Application Service Account"
  description  = "Service account for application workloads"
}

# Custom role with specific permissions
resource "google_project_iam_custom_role" "app_role" {
  role_id     = "customAppRole"
  title       = "Custom Application Role"
  description = "Custom role for application with minimal permissions"
  permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "pubsub.messages.get",
    "pubsub.subscriptions.consume"
  ]
}

# Bind custom role to service account
resource "google_project_iam_member" "app_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.app_role.name
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### Policy Validation
```bash
# Validate IAM policies before applying
gcloud iam policies lint-condition \
  --condition-file=condition.yaml
```

## Emergency Access Procedures

### Break-Glass Access
```bash
# Create emergency access group
gcloud identity groups create emergency-access@company.com \
  --display-name="Emergency Access Group" \
  --description="For emergency situations only"

# Grant temporary elevated permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="group:emergency-access@company.com" \
  --role="roles/owner" \
  --condition="expression=request.time < timestamp('2024-12-31T23:59:59Z')"
```

### Incident Response
1. **Immediate Response**
   - Identify scope of compromise
   - Disable affected accounts
   - Revoke suspicious permissions

2. **Investigation**
   - Review audit logs
   - Identify attack vectors
   - Document timeline

3. **Recovery**
   - Restore legitimate access
   - Implement additional controls
   - Update security policies

## Compliance Considerations

### Regulatory Requirements
- **SOX**: Segregation of duties, access reviews
- **GDPR**: Data access controls, audit trails
- **HIPAA**: Minimum necessary access, logging
- **PCI DSS**: Network segmentation, access controls

### Documentation Requirements
- **Access Control Matrix**: Who has access to what
- **Role Definitions**: Purpose and permissions of each role
- **Review Procedures**: How access is reviewed and updated
- **Incident Procedures**: Response to access violations

## Common Anti-Patterns to Avoid

### 1. Over-Privileged Accounts
```bash
# Bad: Granting broad permissions
--role="roles/owner"

# Good: Granting specific permissions
--role="roles/storage.objectViewer"
```

### 2. Shared Service Accounts
```bash
# Bad: One service account for everything
shared-app-sa@project.iam.gserviceaccount.com

# Good: Dedicated service accounts
web-frontend-sa@project.iam.gserviceaccount.com
data-processor-sa@project.iam.gserviceaccount.com
```

### 3. Long-Lived Credentials
```bash
# Bad: Service account keys that never expire
gcloud iam service-accounts keys create key.json

# Good: Use Workload Identity or short-lived tokens
gcloud auth application-default print-access-token
```

### 4. Manual Permission Management
```bash
# Bad: Manual role assignments
gcloud projects add-iam-policy-binding ...

# Good: Infrastructure as Code
terraform apply iam-config/
```

## Tools and Resources

### Google Cloud Tools
- **Cloud Console**: Web-based IAM management
- **gcloud CLI**: Command-line IAM operations  
- **Cloud Shell**: Browser-based CLI access
- **Policy Simulator**: Test IAM policies before applying

### Third-Party Tools
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management
- **HashiCorp Vault**: Secrets management
- **Forseti Security**: Compliance monitoring

### Monitoring and Analysis
- **Cloud Logging**: Audit log analysis
- **Cloud Monitoring**: IAM metrics and alerts
- **Security Command Center**: Security findings
- **BigQuery**: Large-scale log analysis

By following these best practices, you can build a robust, secure, and maintainable IAM system that scales with your organization's needs while maintaining strong security posture.