variable "ecr_name" {
  type = string
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}
