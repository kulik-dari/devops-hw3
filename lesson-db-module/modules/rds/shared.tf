# ─── Shared: DB Subnet Group ───────────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.identifier}"
  tags = {
    Name      = "${var.identifier}-subnet-group"
    ManagedBy = "Terraform"
  }
}

# ─── Shared: Security Group ─────────────────────────────────────────────────
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier} database"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB access from allowed CIDRs"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.identifier}-sg"
    ManagedBy = "Terraform"
  }
}

# ─── Shared: Parameter Group ────────────────────────────────────────────────
resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.identifier}-params"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.identifier}"

  parameter {
    name         = "max_connections"
    value        = var.max_connections
    apply_method = "pending-reboot"
  }

  dynamic "parameter" {
    for_each = local.is_postgres ? [1] : []
    content {
      name         = "log_statement"
      value        = var.log_statement
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = local.is_postgres ? [1] : []
    content {
      name         = "work_mem"
      value        = var.work_mem
      apply_method = "immediate"
    }
  }

  tags = {
    Name      = "${var.identifier}-params"
    ManagedBy = "Terraform"
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.identifier}-cluster-params"
  family      = local.parameter_group_family
  description = "Cluster parameter group for ${var.identifier}"

  parameter {
    name         = "max_connections"
    value        = var.max_connections
    apply_method = "pending-reboot"
  }

  dynamic "parameter" {
    for_each = local.is_postgres ? [1] : []
    content {
      name         = "log_statement"
      value        = var.log_statement
      apply_method = "immediate"
    }
  }

  tags = {
    Name      = "${var.identifier}-cluster-params"
    ManagedBy = "Terraform"
  }
}

# ─── Local values ────────────────────────────────────────────────────────────
locals {
  is_postgres = contains(["postgres", "aurora-postgresql"], var.engine)
  is_mysql    = contains(["mysql", "aurora-mysql"], var.engine)

  db_port = local.is_postgres ? 5432 : 3306

  parameter_group_family = local.is_postgres ? (
    var.use_aurora ? "aurora-postgresql15" : "postgres15"
  ) : (
    var.use_aurora ? "aurora-mysql8.0" : "mysql8.0"
  )
}
