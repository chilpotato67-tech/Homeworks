variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "step-project-3"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "eu-central-1a"
}

variable "key_pair_name" {
  description = "Existing AWS key pair name"
  type        = string
  default     = "pr1"
}

variable "public_key_path" {
  description = "Path to local public SSH key"
  type        = string
  default     = "../../pr1.pub"
}

variable "master_instance_type" {
  description = "EC2 instance type for Jenkins master"
  type        = string
  default     = "t3.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for Jenkins worker"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu AMI ID for eu-central-1"
  type        = string
  default     = "ami-005f97cc4a61dd3b4"
}