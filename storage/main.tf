terraform {
  backend "s3" {
    bucket         = "kroton-terraform-remote-state"
    key            = "kroton/storage-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kroton-terraform-lock-table"
    encrypt        = true
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "kroton-terraform-remote-state"
    key    = "kroton/vpc-terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "kroton-terraform-remote-state"
    key    = "kroton/security-terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_efs_file_system" "kroton-efs" {
  creation_token   = "kroton-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Terraform = "true"
  }
}

resource "aws_efs_mount_target" "efs-kroton-mt" {
  file_system_id  = aws_efs_file_system.kroton-efs.id
  subnet_id       = var.env == "prod" ? data.terraform_remote_state.vpc.outputs.public_subnet_prod_ids[0] : data.terraform_remote_state.vpc.outputs.public_subnet_dev_ids[0]
  security_groups = var.env == "prod" ? [data.terraform_remote_state.security.outputs.sg_allow_prod_efs] : [data.terraform_remote_state.security.outputs.sg_allow_dev_efs]
}