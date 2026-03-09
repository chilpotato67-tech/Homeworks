output "vpc_id" {
  value = aws_vpc.homework_vpc.id
}

output "subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "instance_public_ip" {
  value = module.web_ec2.instance_public_ip
}

output "instance_public_url" {
  value = "http://${module.web_ec2.instance_public_ip}"
}