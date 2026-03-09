variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID"
  type        = string
}

variable "list_of_open_ports" {
  description = "Ports to allow from 0.0.0.0/0"
  type        = list(number)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = null
}