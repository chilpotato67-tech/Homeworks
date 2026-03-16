output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins master"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_master_private_ip" {
  description = "Private IP of Jenkins master"
  value       = aws_instance.jenkins_master.private_ip
}

output "jenkins_worker_private_ip" {
  description = "Private IP of Jenkins worker"
  value       = aws_spot_instance_request.jenkins_worker.private_ip
}

output "jenkins_master_instance_id" {
  description = "Instance ID of Jenkins master"
  value       = aws_instance.jenkins_master.id
}

output "jenkins_worker_spot_request_id" {
  description = "Spot request ID of Jenkins worker"
  value       = aws_spot_instance_request.jenkins_worker.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat.id
}