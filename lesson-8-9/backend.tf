# IMPORTANT: Before using this backend, first run:
#   terraform init && terraform apply -target=module.s3_backend
# Then uncomment and run: terraform init -migrate-state

terraform {
  backend "s3" {
    bucket         = "dariia-kulikova-tf-state-lesson8"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson8"
    encrypt        = true
  }
}
