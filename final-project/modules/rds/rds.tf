# ─── Standard RDS Instance (use_aurora = false) ─────────────────────────────
resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = local.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name

  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  backup_retention_period = var.backup_retention_period

  tags = {
    Name      = var.identifier
    ManagedBy = "Terraform"
  }
}
