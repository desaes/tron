output "cr_EC2_cloud_watch_logs_id" {
  value = aws_iam_role.cr-EC2-cloud-watch-logs.id
}

output "cr_EC2_cloud_watch_logs_arn" {
  value = aws_iam_role.cr-EC2-cloud-watch-logs.arn
}

output "cp_EC2_cloud_watch_logs_id" {
  value = aws_iam_policy.cp-EC2-cloud-watch-logs.id
}

output "cp_EC2_cloud_watch_logs_arn" {
  value = aws_iam_policy.cp-EC2-cloud-watch-logs.arn
}

output "ip_EC2_cloud_watch_logs_id" {
  value = aws_iam_instance_profile.ip-EC2-cloud-watch-logs.id
}

output "ip_EC2_cloud_watch_logs_arn" {
  value = aws_iam_instance_profile.ip-EC2-cloud-watch-logs.arn
}