terraform {
  backend "s3" {
    bucket         = "kroton-terraform-remote-state"
    key            = "kroton/vpc-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kroton-terraform-lock-table"
    encrypt        = true
  }
}

module "vpc-dev" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.11.0"

  name = "kroton-dev-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "vpc-prod" {
  source = "terraform-aws-modules/vpc/aws"

  name = "kroton-prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}