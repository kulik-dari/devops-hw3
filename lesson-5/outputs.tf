# ── S3 Backend Outputs ──────────────────────────────────────────────────────
output "s3_bucket_id" {
  description = "The name of the S3 bucket used for Terraform state"
  value       = module.s3_backend.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = module.s3_backend.bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# ── VPC Outputs ──────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# ── ECR Outputs ──────────────────────────────────────────────────────────────
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = module.ecr.registry_id
}
