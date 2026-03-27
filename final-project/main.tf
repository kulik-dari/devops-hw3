terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

variable "region" {
  default = "us-west-2"
}

variable "student_name" {
  default = "dariia-kulikova"
}

variable "github_repo_url" {
  default = "https://github.com/kulik-dari/devops-hw3"
}

variable "db_password" {
  default   = "DevOpsSecret123!"
  sensitive = true
}

# ─── S3 Backend ─────────────────────────────────────────────────────────────
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "${var.student_name}-tf-state-final"
  table_name  = "terraform-locks-final"
}

# ─── VPC ────────────────────────────────────────────────────────────────────
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "final-vpc"
  cluster_name       = "final-eks"
}

# ─── ECR ────────────────────────────────────────────────────────────────────
module "ecr" {
  source               = "./modules/ecr"
  ecr_name             = "final-django"
  scan_on_push         = true
  image_tag_mutability = "MUTABLE"
}

# ─── EKS ────────────────────────────────────────────────────────────────────
module "eks" {
  source            = "./modules/eks"
  cluster_name      = "final-eks"
  cluster_version   = "1.29"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_types    = ["t3.medium"]
  desired_size      = 2
  min_size          = 1
  max_size          = 4
}

# ─── RDS ────────────────────────────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  identifier     = "final-postgres"
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.10"
  instance_class = "db.t3.micro"

  db_name  = "djangodb"
  username = "djangoadmin"
  password = var.db_password

  multi_az            = false
  subnet_ids          = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  depends_on = [module.vpc]
}

# ─── Jenkins ─────────────────────────────────────────────────────────────────
module "jenkins" {
  source          = "./modules/jenkins"
  cluster_name    = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  ecr_repo_url    = module.ecr.repository_url
  aws_region      = var.region
  github_repo_url = var.github_repo_url

  depends_on = [module.eks]
}

# ─── ArgoCD ──────────────────────────────────────────────────────────────────
module "argo_cd" {
  source           = "./modules/argo_cd"
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  github_repo_url  = var.github_repo_url
  ecr_repo_url     = module.ecr.repository_url

  depends_on = [module.eks, module.jenkins]
}

# ─── Monitoring (Prometheus + Grafana) ───────────────────────────────────────
module "monitoring" {
  source       = "./modules/monitoring"
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}
