output "vpc_id" {
  value = aws_vpc.my_aws_vpc.id
}
output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1
}
output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2
}
output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1
}
output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2
}
output "ec2_sg_id" {
  value = aws_security_group.ec2
}
output "rds_sg_id" {
  value = aws_security_group.rds
}
output "alb_dns_name" {
  value = aws_lb.tg.dns_name
}
output "alb_arn" {
  value = aws_lb.tg.arn
}
output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}
output "rds_port" {
  value = aws_db_instance.rds.port
}
output "secret_arn" {
  value = aws_secretsmanager_secret.rds_secret.arn
}
output "db_name" {
  value = aws_db_instance.rds.db_name
}