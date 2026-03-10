# Backend configuration for Terraform state storage
# IMPORTANT: Before using this backend, you must first create the S3 bucket and DynamoDB table
# by running: terraform apply -target=module.s3_backend
# Then uncomment and run: terraform init -migrate-state

# terraform {
#   backend "s3" {
#     bucket         = "your-name-terraform-state"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }

# NOTE: The backend block is commented out by default because the S3 bucket
# and DynamoDB table must exist BEFORE Terraform can use them as a backend.
#
# Steps to enable remote backend:
# 1. Run: terraform init && terraform apply -target=module.s3_backend
# 2. Uncomment the backend block above
# 3. Replace "your-name-terraform-state" with your actual bucket name (var.student_name value)
# 4. Run: terraform init -migrate-state
# 5. Confirm migration when prompted
