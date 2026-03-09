# Homework21 - AWS Terraform and Ansible

## Files
- main.tf
- playbook.yml
- docker-compose.yml
- inventory.ini (generated automatically by Terraform)

## Commands
terraform init
terraform plan
terraform apply

ansible -i inventory.ini webservers -m ping
ansible-playbook -i inventory.ini playbook.yml

terraform destroy
