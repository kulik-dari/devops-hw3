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
  bucket_name = "${var.student_name}-terraform-state-lesson7"
  table_name  = "terraform-locks-lesson7"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

module "ecr" {
  source               = "./modules/ecr"
  ecr_name             = "lesson-7-django"
  scan_on_push         = true
  image_tag_mutability = "MUTABLE"
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "lesson-7-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = ["t3.medium"]
  desired_size    = 2
  min_size        = 1
  max_size        = 4
}
