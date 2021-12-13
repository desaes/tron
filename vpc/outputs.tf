output "vpc_dev_id" {
  value = module.vpc-dev.vpc_id
}

output "vpc_prod_id" {
  value = module.vpc-prod.vpc_id
}

output "private_subnet_dev_ids" {
  value = module.vpc-dev.public_subnets
}

output "public_subnet_dev_ids" {
  value = module.vpc-dev.public_subnets
}

output "private_subnet_prod_ids" {
  value = module.vpc-prod.public_subnets
}

output "public_subnet_prod_ids" {
  value = module.vpc-prod.public_subnets
}