output "bucket_id" { value = aws_s3_bucket.terraform_state.id }
output "dynamodb_table_name" { value = aws_dynamodb_table.terraform_locks.name }
