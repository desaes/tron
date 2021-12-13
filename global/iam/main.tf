terraform {
  backend "s3" {
    bucket         = "kroton-terraform-remote-state"
    key            = "kroton/iam-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kroton-terraform-lock-table"
    encrypt        = true
  }
}

resource "aws_iam_role" "cr-EC2-cloud-watch-logs" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Terraform = "true"
  }
}


resource "aws_iam_policy" "cp-EC2-cloud-watch-logs" {
  name = "CpEC2CloudWatchLogs"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:*:*:*"
        ]
      },
    ]
  })

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_role_policy_attachment" "pa-cloudwatch-ec2-policy-attach" {
  policy_arn = aws_iam_policy.cp-EC2-cloud-watch-logs.arn
  role       = aws_iam_role.cr-EC2-cloud-watch-logs.name
}

resource "aws_iam_instance_profile" "ip-EC2-cloud-watch-logs" {
  name = "ip-EC2-cloud-watch-logs"
  role = aws_iam_role.cr-EC2-cloud-watch-logs.name

  tags = {
    Terraform = "true"
  }
}