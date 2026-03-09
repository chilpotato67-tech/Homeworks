provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "homework_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ce-moi-zminy-homework20-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.homework_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "homework20-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.homework_vpc.id

  tags = {
    Name = "homework20-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.homework_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "homework20-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

module "web_ec2" {
  source = "./modules/web_ec2"

  vpc_id             = aws_vpc.homework_vpc.id
  subnet_id          = aws_subnet.public_subnet.id
  list_of_open_ports = var.list_of_open_ports
  instance_type      = var.instance_type
  key_name           = var.key_name
}