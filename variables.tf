variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "lambda_name" {
  type    = string
  default = "link-redirector"

  validation {
    condition = can(regex("^[0-9A-Za-z-_]+$", var.lambda_name))
    error_message = "Value must match the following regex: ^[0-9A-Za-z-_]+$"
  }
}

variable "log_storage_retention" {
  type    = number
  default = "30"  # days
}
