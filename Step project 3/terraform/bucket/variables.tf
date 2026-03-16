variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Unique name for Terraform state S3 bucket"
  type        = string
}