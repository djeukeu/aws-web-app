variable "app_name" {
  type = string
}

variable "aws_region" {
  default = "us-east-1"
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Wrong environment value!"
  }
}

variable "container_image" {
  type = string
}

variable "desired_count" {
  type     = number
  default  = 2
  nullable = true
}
