output "efs_kroton_id" {
  value = aws_efs_mount_target.efs-kroton-mt.id
}

output "efs_kroton_dns" {
  value = aws_efs_mount_target.efs-kroton-mt.dns_name
}

output "efs_kroton_mdns" {
  value = aws_efs_mount_target.efs-kroton-mt.mount_target_dns_name
}
