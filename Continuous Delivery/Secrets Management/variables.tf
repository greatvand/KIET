variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
    default     = "us-east-1"
}

variable "db_username" {
  description = "Username for RDS database"
  type        = string
  default     = "adminuser"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "studentdb"
}