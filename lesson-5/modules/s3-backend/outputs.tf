output "bucket_id" {
  description = "The name/ID of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name (URL)"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}
