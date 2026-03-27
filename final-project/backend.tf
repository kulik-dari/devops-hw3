# IMPORTANT: Before using this backend, first run:
#   terraform init && terraform apply -target=module.s3_backend
# Then uncomment and run: terraform init -migrate-state

terraform {
  backend "s3" {
    bucket         = "dariia-kulikova-tf-state-final"
    key            = "final-project/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-final"
    encrypt        = true
  }
}
