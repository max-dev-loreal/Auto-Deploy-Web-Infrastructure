output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_1_id" {
  value = module.networking.public_subnet_1_id
}

output "public_subnet_2_id" {
  value = module.networking.public_subnet_2_id
}

output "private_subnet_1_id" {
  value = module.networking.private_subnet_1_id
}

output "private_subnet_2_id" {
  value = module.networking.private_subnet_2_id
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "alb_arn" {
  value = module.compute.alb_arn
}

output "asg_name" {
  value = module.compute.asg_name
}

output "ec2_sg_id" {
  value = module.compute.ec2_sg_id
}

output "rds_endpoint" {
  value = module.database.rds_endpoint
}

output "rds_port" {
  value = module.database.rds_port
}

output "secret_arn" {
  value = module.database.secret_arn
}

output "db_name" {
  value = module.database.db_name
}