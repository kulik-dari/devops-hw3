# IMPORTANT: Before using this backend, first run:
#   terraform init && terraform apply -target=module.s3_backend
# Then uncomment and run: terraform init -migrate-state

# terraform {
#   backend "s3" {
#     bucket         = "dariia-kulikova-tf-state-db-module"
#     key            = "lesson-db-module/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-db-module"
#     encrypt        = true
#   }
# }
