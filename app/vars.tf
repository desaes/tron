variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

variable "env" {
  default = "dev"
}
variable "instance_type" {
  default = "t2.micro"
}

variable "path_to_private_key" {
  default = "ssh-key"
}
variable "path_to_public_key" {
  default = "ssh-key.pub"
}
