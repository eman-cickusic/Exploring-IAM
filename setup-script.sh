#!/bin/bash

# Google Cloud IAM Lab Setup Script
# This script automates the setup process for the IAM lab

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if gcloud is installed and authenticated
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to set up project variables
setup_variables() {
    print_status "Setting up variables..."
    
    # Get current project ID
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi
    
    # Generate unique bucket name
    BUCKET_NAME="${PROJECT_ID}-iam-lab-$(date +%s)"
    SERVICE_ACCOUNT_NAME="read-bucket-objects"
    VM_NAME="demoiam"
    ZONE=$(gcloud config get-value compute/zone)
    
    if [ -z "$ZONE" ]; then
        print_warning "No default zone set. Using us-central1-a"
        ZONE="us-central1-a"
        gcloud config set compute/zone $ZONE
    fi
    
    print_success "Variables configured"
    echo "  Project ID: $PROJECT_ID"
    echo "  Bucket Name: $BUCKET_NAME"
    echo "  Zone: $ZONE"
}

# Function to create Cloud Storage bucket
create_storage_bucket() {
    print_status "Creating Cloud Storage bucket..."
    
    if gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
        print_warning "Bucket $BUCKET_NAME already exists"
    else
        gsutil mb -l us gs://$BUCKET_NAME
        print_success "Created bucket: $BUCKET_NAME"
    fi
    
    # Create and upload sample file
    echo "This is a sample file for IAM testing" > sample.txt
    gsutil cp sample.txt gs://$BUCKET_NAME/
    print_success "Uploaded sample.txt to bucket"
    
    # Clean up local file
    rm sample.txt
}

# Function to create service account
create_service_account() {
    print_status "Creating service account..."
    
    # Check if service account already exists
    if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com &> /dev/null; then
        print_warning "Service account $SERVICE_ACCOUNT_NAME already exists"
    else
        gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
            --display-name="Read Bucket Objects" \
            --description="Service account for reading bucket objects"
        print_success "Created service account: $SERVICE_ACCOUNT_NAME"
    fi
    
    # Assign Storage Object Viewer role
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/storage.objectViewer"
    print_success "Assigned Storage Object Viewer role to service account"
}

# Function to create VM instance
create_vm_instance() {
    print_status "Creating VM instance..."
    
    # Check if VM already exists
    if gcloud compute instances describe $VM_NAME --zone=$ZONE &> /dev/null; then
        print_warning "VM instance $VM_NAME already exists"
    else
        gcloud compute instances create $VM_NAME \
            --zone=$ZONE \
            --machine-type=e2-micro \
            --image-family=debian-12 \
            --image-project=debian-cloud \
            --service-account="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
            --scopes=storage-rw,compute-ro \
            --tags=iam-lab
        print_success "Created VM instance: $VM_NAME"
    fi
}

# Function to set up IAM permissions for domain
setup_domain_permissions() {
    print_status "Setting up domain permissions..."
    
    # Grant Service Account User role to altostrat.com domain
    gcloud iam service-accounts add-iam-policy-binding \
        "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --member="domain:altostrat.com" \
        --role="roles/iam.serviceAccountUser"
    print_success "Granted Service Account User role to altostrat.com"
    
    # Grant Compute Instance Admin role to altostrat.com domain
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="domain:altostrat.com" \
        --role="roles/compute.instanceAdmin.v1"
    print_success "Granted Compute Instance Admin role to altostrat.com"
}

# Function to create test script
create_test_script() {
    print_status "Creating test script..."
    
    cat > test_permissions.sh << EOF
#!/bin/bash
# Test script for verifying IAM permissions

echo "Testing IAM permissions..."
echo "Bucket name: $BUCKET_NAME"
echo "=========================="

# Test 1: List compute instances (should fail initially)
echo "Test 1: Listing compute instances"
if gcloud compute instances list; then
    echo "✓ Can list compute instances"
else
    echo "✗ Cannot list compute instances (expected for service account)"
fi

echo ""

# Test 2: Download file from bucket (should succeed)
echo "Test 2: Downloading file from bucket"
if gcloud storage cp gs://$BUCKET_NAME/sample.txt .; then
    echo "✓ Successfully downloaded sample.txt"
else
    echo "✗ Failed to download sample.txt"
    exit 1
fi

# Test 3: Rename file
echo "Test 3: Renaming file"
if mv sample.txt sample2.txt; then
    echo "✓ Successfully renamed file"
else
    echo "✗ Failed to rename file"
    exit 1
fi

# Test 4: Upload file to bucket (may fail initially)
echo "Test 4: Uploading file to bucket"
if gcloud storage cp sample2.txt gs://$BUCKET_NAME/; then
    echo "✓ Successfully uploaded sample2.txt"
else
    echo "✗ Failed to upload sample2.txt (check if Storage Object Creator role is assigned)"
fi

echo ""
echo "Test completed!"
EOF

    chmod +x test_permissions.sh
    print_success "Created test_permissions.sh script"
}

# Function to display summary
display_summary() {
    print_success "Setup completed successfully!"
    echo ""
    echo "Resources created:"
    echo "  • Cloud Storage bucket: gs://$BUCKET_NAME"
    echo "  • Service account: ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    echo "  • VM instance: $VM_NAME (zone: $ZONE)"
    echo ""
    echo "Next steps:"
    echo "  1. SSH to the VM: gcloud compute ssh $VM_NAME --zone=$ZONE"
    echo "  2. Run the test script: ./test_permissions.sh"
    echo "  3. To grant Storage Object Creator role:"
    echo "     gcloud projects add-iam-policy-binding $PROJECT_ID \\"
    echo "       --member=\"serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com\" \\"
    echo "       --role=\"roles/storage.objectCreator\""
    echo ""
    echo "Bucket name for reference: $BUCKET_NAME"
}

# Main execution
main() {
    echo "Starting Google Cloud IAM Lab Setup"
    echo "===================================="
    
    check_prerequisites
    setup_variables
    create_storage_bucket
    create_service_account
    create_vm_instance
    setup_domain_permissions
    create_test_script
    display_summary
}

# Run the main function
main "$@"