terraform {### зміна в тераформ 
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "chilpotato67-terraform-state-homework20"
    key    = "chilpotato67/homework20/terraform.tfstate"
    region = "eu-central-1"
  }
}