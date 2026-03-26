terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-west-2"
}

variable "student_name" {
  default = "dariia-kulikova"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "${var.student_name}-tf-state-db-module"
  table_name  = "terraform-locks-db-module"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b"]
  vpc_name           = "db-module-vpc"
}

# Приклад 1: Звичайна RDS PostgreSQL
module "rds_postgres" {
  source = "./modules/rds"

  identifier     = "lesson-db-postgres"
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.10"
  instance_class = "db.t3.micro"

  db_name  = "appdb"
  username = "dbadmin"
  password = "SuperSecret123!"

  multi_az           = false
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
}

# Приклад 2: Aurora PostgreSQL
module "rds_aurora" {
  source = "./modules/rds"

  identifier     = "lesson-db-aurora"
  use_aurora     = true
  engine         = "aurora-postgresql"
  engine_version = "15.10"
  instance_class = "db.t3.medium"

  db_name  = "auroradb"
  username = "auroraadmin"
  password = "AuroraSecret123!"

  multi_az           = false
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
}
