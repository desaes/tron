# output "public_eip" {
#   value = aws_eip.kroton-eip.public_ip
# }

output "aws_elb_dns" {
  value = aws_elb.kroton-elb.dns_name
}