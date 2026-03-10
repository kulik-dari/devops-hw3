variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "vpc_name" {
  description = "Name prefix for all VPC resources"
  type        = string
  default     = "lesson-5-vpc"
}
