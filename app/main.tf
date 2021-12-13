terraform {
  backend "s3" {
    bucket         = "kroton-terraform-remote-state"
    key            = "kroton/app-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kroton-terraform-lock-table"
    encrypt        = true
  }
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform-key"
  public_key = file("${var.path_to_public_key}")
}

data "aws_ami" "ubuntu-amis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
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

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = "kroton-terraform-remote-state"
    key    = "kroton/iam-terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"

  config = {
    bucket = "kroton-terraform-remote-state"
    key    = "kroton/storage-terraform.tfstate"
    region = "us-east-1"
  }
}

data "template_file" "init" {
  template = file("nginx_deploy.sh")

  vars = {
    logs_nfs_endpoint = data.terraform_remote_state.storage.outputs.efs_kroton_dns
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.3.0"

  name = "krotron-app"

  ami                    = data.aws_ami.ubuntu-amis.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.terraform.key_name
  iam_instance_profile   = data.terraform_remote_state.iam.outputs.ip_EC2_cloud_watch_logs_id
  monitoring             = false
  subnet_id              = var.env == "prod" ? data.terraform_remote_state.vpc.outputs.public_subnet_prod_ids[0] : data.terraform_remote_state.vpc.outputs.public_subnet_dev_ids[0]
  vpc_security_group_ids = var.env == "prod" ? [data.terraform_remote_state.security.outputs.sg_allow_prod_ssh, data.terraform_remote_state.security.outputs.sg_allow_prod_http, data.terraform_remote_state.security.outputs.sg_allow_prod_https] : [data.terraform_remote_state.security.outputs.sg_allow_dev_ssh, data.terraform_remote_state.security.outputs.sg_allow_dev_http, data.terraform_remote_state.security.outputs.sg_allow_dev_https]
  user_data              = data.template_file.init.rendered

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}



resource "aws_eip" "kroton-eip" {
  instance = module.ec2_instance.id
  vpc      = true
}
