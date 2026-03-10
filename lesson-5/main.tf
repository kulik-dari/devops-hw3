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
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "student_name" {
  description = "Your name (used for S3 bucket naming)"
  type        = string
  default     = "dariia-kulikova-terraform-state"
}

# S3 Backend Module
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.student_name
  table_name  = "terraform-locks"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-5-vpc"
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}
