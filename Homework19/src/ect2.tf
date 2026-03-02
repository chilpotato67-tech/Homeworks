data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_security_group" "ssh_access" {
  name   = "allow_ssh_frankfurt"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal_ssh" {
  name   = "allow_ssh_internal"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "pr1-key"
  public_key = file("${path.module}/pr1.pub") 
}

resource "aws_instance" "my_web_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh_access.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = { Name = "Frankfurt-Server-PUBLIC" }
}

resource "aws_instance" "private_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.internal_ssh.id]
  key_name               = aws_key_pair.deployer.key_name
  
  tags = { Name = "Frankfurt-Server-PRIVATE" }
}

output "server_public_ip" {
  value = aws_instance.my_web_server.public_ip
}

output "private_server_internal_ip" {
  value = aws_instance.private_server.private_ip
}