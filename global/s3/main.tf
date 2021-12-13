terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      version = "~> 2.0"
    }
  }

  # Uncomment the following block to move the state to remote
  #backend "s3" {
  #  bucket = "tron-terraform-remote-state"
  #  key    = "tron/s3-terraform.tfstate"
  #  region = "us-east-1"
  #  dynamodb_table = "tron-terraform-lock-table"
  #  encrypt        = true
  #}

}

resource "aws_s3_bucket" "terraform_state" {

  bucket = var.bucket_name

  # This is only here so we can destroy the bucket as part of automated tests. 
  # You should not use this for production usage.
  force_destroy = true

  # Keep this bucket safe from accidental destruction
  lifecycle {
    prevent_destroy = false
  }

  # Enable versioning so we can see the full revision history of our state 
  # files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}