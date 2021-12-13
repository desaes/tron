variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}