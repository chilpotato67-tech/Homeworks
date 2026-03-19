resource "aws_instance" "jenkins_master" {
  ami                         = var.ami_id
  instance_type               = var.master_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.jenkins_master_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -e
              mkdir -p /home/ubuntu/.ssh
              echo "${trimspace(file(var.public_key_path))}" >> /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              apt-get update -y
              EOF

  tags = {
    Name    = "${var.project_name}-jenkins-master"
    Project = var.project_name
    Role    = "jenkins-master"
  }
}

resource "aws_spot_instance_request" "jenkins_worker" {
  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.jenkins_worker_sg.id]
  key_name               = var.key_pair_name
  spot_type = "persistent"
  wait_for_fulfillment   = true

  user_data = <<-EOF
              #!/bin/bash
              set -e
              mkdir -p /home/ubuntu/.ssh
              echo "${trimspace(file(var.public_key_path))}" >> /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              apt-get update -y
              EOF

  tags = {
    Name    = "${var.project_name}-jenkins-worker"
    Project = var.project_name
    Role    = "jenkins-worker"
  }
}
