variable "list_of_open_ports" {
  description = "List of ports to open from everywhere"
  type        = list(number)
  default     = [22, 80]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "pr1"
}