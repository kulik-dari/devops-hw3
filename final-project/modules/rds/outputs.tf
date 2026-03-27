output "db_endpoint" {
  value = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].endpoint
  description = "Endpoint для підключення до БД"
}

output "db_port" {
  value       = local.db_port
  description = "Порт БД"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "ID Security Group"
}

output "subnet_group_name" {
  value       = aws_db_subnet_group.this.name
  description = "Назва DB Subnet Group"
}

output "db_type" {
  value       = var.use_aurora ? "Aurora Cluster" : "RDS Instance"
  description = "Тип розгорнутої БД"
}
