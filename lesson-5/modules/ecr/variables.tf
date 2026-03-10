variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9._/-]{2,256}$", var.ecr_name))
    error_message = "ECR repository name must be 2-256 characters and contain only lowercase letters, numbers, hyphens, underscores, forward slashes, and periods."
  }
}

variable "scan_on_push" {
  description = "Enable automatic image scanning on push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}
