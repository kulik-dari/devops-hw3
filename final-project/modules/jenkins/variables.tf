variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "ecr_repo_url" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "github_repo_url" {
  type = string
}
