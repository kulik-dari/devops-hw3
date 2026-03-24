variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_name" {
  type    = string
  default = "lesson-8-vpc"
}

variable "cluster_name" {
  type    = string
  default = "lesson-8-eks"
}
