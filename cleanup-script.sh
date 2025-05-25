#!/bin/bash

# Google Cloud IAM Lab Cleanup Script
# This script removes all resources created during the IAM lab

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

# Function to confirm cleanup
confirm_cleanup() {
    echo -e "${YELLOW}WARNING: This will delete all resources created during the IAM lab!${NC}"
    echo "This includes:"
    echo "  • Cloud Storage buckets with 'iam-lab' in the name"
    echo "  • Service account 'read-bucket-objects'"
    echo "  • VM instance 'demoiam'"
    echo "  • Associated IAM policy bindings"
    echo ""
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Function to get project variables
setup_variables() {
    print_status "Setting up variables..."
    
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi
    
    SERVICE_ACCOUNT_NAME="read-bucket-objects"
    VM_NAME="demoiam"
    ZONE=$(gcloud config get-value compute/zone)
    
    if [ -z "$ZONE" ]; then
        ZONE="us-central1-a"
    fi
    
    print_success "Variables configured"
    echo "  Project ID: $PROJECT_ID"
    echo "  Service Account: $SERVICE_ACCOUNT_NAME"
    echo "  VM Name: $VM_NAME"
    echo "  Zone: $ZONE"
}

# Function to delete VM instance
delete_vm_instance() {
    print_status "Deleting VM instance..."
    
    if gcloud compute instances describe $VM_NAME --zone=$ZONE &> /dev/null; then
        gcloud compute instances delete $VM_NAME --zone=$ZONE --quiet
        print_success "Deleted VM instance: $VM_NAME"
    else
        print_warning "VM instance $VM_NAME not found"
    fi
}

# Function to delete Cloud Storage buckets
delete_storage_buckets() {
    print_status "Deleting Cloud Storage buckets..."
    
    # Find buckets with 'iam-lab' in the name
    BUCKETS=$(gsutil ls -b | grep -E "${PROJECT_ID}.*iam-lab" || true)
    
    if [ -z "$BUCKETS" ]; then
        print_warning "No IAM lab buckets found"
    else
        for bucket in $BUCKETS; do
            print_status "Deleting bucket: $bucket"
            gsutil rm -r $bucket
            print_success "Deleted bucket: $bucket"
        done
    fi
}

# Function to remove IAM policy bindings
remove_iam_bindings() {
    print_status "Removing IAM policy bindings..."
    
    SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Remove Storage Object Viewer role from service account
    if gcloud projects get-iam-policy $PROJECT_ID --format=json | grep -q $SERVICE_ACCOUNT_EMAIL; then
        gcloud projects remove-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role="roles/storage.objectViewer" || true
        print_success "Removed Storage Object Viewer role from service account"
    fi
    
    # Remove Storage Object Creator role from service account (if exists)
    gcloud projects remove-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/storage.objectCreator" || true
    
    # Remove domain-level bindings
    gcloud projects remove-iam-policy-binding $PROJECT_ID \
        --member="domain:altostrat.com" \
        --role="roles/compute.instanceAdmin.v1" || true
    print_success "Removed domain IAM bindings"
    
    # Remove service account user binding
    gcloud iam service-accounts remove-iam-policy-binding \
        $SERVICE_ACCOUNT_EMAIL \
        --member="domain:altostrat.com" \
        --role="roles/iam.serviceAccountUser" || true
    print_success "Removed Service Account User binding"
}

# Function to delete service account
delete_service_account() {
    print_status "Deleting service account..."
    
    SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &> /dev/null; then
        gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL --quiet
        print_success "Deleted service account: $SERVICE_ACCOUNT_EMAIL"
    else
        print_warning "Service account $SERVICE_ACCOUNT_EMAIL not found"
    fi
}

# Function to clean up local files
cleanup_local_files() {
    print_status "Cleaning up local files..."
    
    # Remove test scripts and sample files
    local files_to_remove=("test_permissions.sh" "sample.txt" "sample2.txt")
    
    for file in "${files_to_remove[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
            print_success "Removed local file: $file"
        fi
    done
}

# Function to display cleanup summary
display_summary() {
    print_success "Cleanup completed successfully!"
    echo ""
    echo "Removed resources:"
    echo "  ✓ VM instances with name 'demoiam'"
    echo "  ✓ Cloud Storage buckets containing 'iam-lab'"
    echo "  ✓ Service account 'read-bucket-objects'"
    echo "  ✓ Associated IAM policy bindings"
    echo "  ✓ Local test files"
    echo ""
    print_status "All IAM lab resources have been cleaned up"
}

# Function to handle errors
handle_error() {
    print_error "An error occurred during cleanup"
    print_status "Some resources may still exist. Please check manually:"
    echo "  • gcloud compute instances list"
    echo "  • gsutil ls -b"
    echo "  • gcloud iam service-accounts list"
    exit 1
}

# Main execution
main() {
    echo "Starting Google Cloud IAM Lab Cleanup"
    echo "====================================="
    
    # Set up error handling
    trap handle_error ERR
    
    confirm_cleanup
    setup_variables
    delete_vm_instance
    delete_storage_buckets
    remove_iam_bindings
    delete_service_account
    cleanup_local_files
    display_summary
}

# Run the main function
main "$@"