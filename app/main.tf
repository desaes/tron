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

# module "ec2_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 3.3.0"

#   name = "krotron-app"

#   ami                    = data.aws_ami.ubuntu-amis.id
#   instance_type          = var.instance_type
#   key_name               = aws_key_pair.terraform.key_name
#   iam_instance_profile   = data.terraform_remote_state.iam.outputs.ip_EC2_cloud_watch_logs_id
#   monitoring             = false
#   subnet_id              = var.env == "prod" ? data.terraform_remote_state.vpc.outputs.public_subnet_prod_ids[0] : data.terraform_remote_state.vpc.outputs.public_subnet_dev_ids[0]
#   vpc_security_group_ids = var.env == "prod" ? [data.terraform_remote_state.security.outputs.sg_allow_prod_ssh, data.terraform_remote_state.security.outputs.sg_allow_prod_http, data.terraform_remote_state.security.outputs.sg_allow_prod_https] : [data.terraform_remote_state.security.outputs.sg_allow_dev_ssh, data.terraform_remote_state.security.outputs.sg_allow_dev_http, data.terraform_remote_state.security.outputs.sg_allow_dev_https]
#   user_data              = data.template_file.init.rendered

#   tags = {
#     Terraform   = "true"
#     Environment = var.env
#   }
# }


# resource "aws_eip" "kroton-eip" {
#   instance = module.ec2_instance.id
#   vpc      = true
# }


resource "aws_elb" "kroton-elb" {
  name            = "kroton-elb"
  subnets         = var.env == "prod" ? [data.terraform_remote_state.vpc.outputs.public_subnet_prod_ids[0]] : [data.terraform_remote_state.vpc.outputs.public_subnet_dev_ids[0]]
  security_groups = var.env == "prod" ? [data.terraform_remote_state.security.outputs.sg_allow_prod_http, data.terraform_remote_state.security.outputs.sg_allow_prod_https] : [data.terraform_remote_state.security.outputs.sg_allow_dev_http, data.terraform_remote_state.security.outputs.sg_allow_dev_https]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # # Certificate must be uploaded to IAM
  # listener {
  #   instance_port     = 80
  #   instance_protocol = "http"
  #   lb_port           = 443
  #   lb_protocol       = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_launch_configuration" "kroton-launchconfig" {

  name_prefix = "kroton-launchconfig"

  image_id                    = data.aws_ami.ubuntu-amis.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.terraform.key_name
  iam_instance_profile        = data.terraform_remote_state.iam.outputs.ip_EC2_cloud_watch_logs_id
  enable_monitoring           = true
  security_groups             = var.env == "prod" ? [data.terraform_remote_state.security.outputs.sg_allow_prod_ssh, data.terraform_remote_state.security.outputs.sg_allow_prod_http, data.terraform_remote_state.security.outputs.sg_allow_prod_https] : [data.terraform_remote_state.security.outputs.sg_allow_dev_ssh, data.terraform_remote_state.security.outputs.sg_allow_dev_http, data.terraform_remote_state.security.outputs.sg_allow_dev_https]
  associate_public_ip_address = true
  user_data                   = data.template_file.init.rendered
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kroton-autoscaling" {
  # Name explicitly depend on the launch configuration's name so each time 
  # it's replaced, this ASG is also replaced
  name                      = "${var.env}-${aws_launch_configuration.kroton-launchconfig.name}"
  vpc_zone_identifier       = var.env == "prod" ? [data.terraform_remote_state.vpc.outputs.public_subnet_prod_ids[0]] : [data.terraform_remote_state.vpc.outputs.public_subnet_dev_ids[0]]
  launch_configuration      = aws_launch_configuration.kroton-launchconfig.name
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  load_balancers            = [aws_elb.kroton-elb.name]
  force_delete              = true

  # Wait for at least this many instances to pass health checks before
  # considering the ASG deployment complete
  min_elb_capacity = var.min_size

  # When replacing this ASG, create the replacement first, and only delete the
  # original after
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

}

