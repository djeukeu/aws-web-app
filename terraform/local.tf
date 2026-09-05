locals {
  common_tags = {
    project     = var.app_name
    managedBy   = "Terraform"
    environment = var.environment
  }
}
