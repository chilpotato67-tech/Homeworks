terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ansible_nginx_sg" {
  name        = "homework21-ansible-nginx-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "homework21-ansible-nginx-sg"
  }
}

resource "aws_instance" "web" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = "pr1"
  vpc_security_group_ids      = [aws_security_group.ansible_nginx_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "homework21-web-${count.index + 1}"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<EOT
[webservers]
${aws_instance.web[0].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./pr1.pem
${aws_instance.web[1].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./pr1.pem
EOT
}

output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "ubuntu_ami_id" {
  value = data.aws_ami.ubuntu.id
}