variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage. Must be globally unique."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters long."
  }
}

variable "table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-locks"
}
