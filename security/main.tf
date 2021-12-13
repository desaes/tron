terraform {
  backend "s3" {
    bucket         = "kroton-terraform-remote-state"
    key            = "kroton/security-terraform.tfstate"
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

resource "aws_security_group" "allow-dev-ssh" {
  name        = "allow-dev-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_dev_id

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
resource "aws_security_group" "allow-dev-http" {
  name        = "allow-dev-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_dev_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "allow-dev-https" {
  name        = "allow-dev-https"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_dev_id

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "allow-prod-ssh" {
  name        = "allow-prod-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_prod_id

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

resource "aws_security_group" "allow-prod-http" {
  name        = "allow-prod-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_prod_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "allow-prod-https" {
  name        = "allow-prod-https"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_prod_id

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "allow-dev-efs" {
  name   = "allow-dev-efs"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_dev_id

  // NFS
  ingress {
    security_groups = [aws_security_group.allow-dev-http.id]
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
  }

  // Terraform removes the default rule
  egress {
    security_groups = [aws_security_group.allow-dev-http.id]
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }
}

resource "aws_security_group" "allow-prod-efs" {
  name   = "allow-prod-efs"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_prod_id

  // NFS
  ingress {
    security_groups = [aws_security_group.allow-prod-http.id]
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
  }

  // Terraform removes the default rule
  egress {
    security_groups = [aws_security_group.allow-prod-http.id]
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }
}

