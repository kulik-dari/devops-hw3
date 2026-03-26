output "s3_bucket_id" {
  value = module.s3_backend.bucket_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "rds_postgres_endpoint" {
  value       = module.rds_postgres.db_endpoint
  description = "RDS PostgreSQL endpoint"
}

output "rds_aurora_endpoint" {
  value       = module.rds_aurora.db_endpoint
  description = "Aurora cluster endpoint"
}
