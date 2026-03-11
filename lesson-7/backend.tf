# Backend configuration for Terraform state storage
# IMPORTANT: Before using this backend, first run:
#   terraform init && terraform apply -target=module.s3_backend
# Then uncomment and run: terraform init -migrate-state

# terraform {
#   backend "s3" {
#     bucket         = "dariia-kulikova-terraform-state-lesson7"
#     key            = "lesson-7/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-lesson7"
#     encrypt        = true
#   }
# }
