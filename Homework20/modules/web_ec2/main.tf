data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-ec2-sg"
  description = "Allow selected inbound ports"
  vpc_id      = var.vpc_id

  tags = {
    Name = "web-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "open_ports" {
  for_each = { for port in var.list_of_open_ports : tostring(port) => port }

  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo '<h1>Nginx is working</h1>' > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "terraform-nginx-ec2"
  }
}