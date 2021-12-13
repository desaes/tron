output "sg_allow_dev_ssh" {
  value = aws_security_group.allow-dev-ssh.id
}

output "sg_allow_dev_http" {
  value = aws_security_group.allow-dev-http.id
}

output "sg_allow_dev_https" {
  value = aws_security_group.allow-dev-https.id
}

output "sg_allow_prod_ssh" {
  value = aws_security_group.allow-prod-ssh.id
}

output "sg_allow_prod_http" {
  value = aws_security_group.allow-prod-http.id
}

output "sg_allow_prod_https" {
  value = aws_security_group.allow-prod-https.id
}

output "sg_allow_dev_efs" {
  value = aws_security_group.allow-dev-efs.id
}

output "sg_allow_prod_efs" {
  value = aws_security_group.allow-prod-efs.id
}