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
output "ec2_public_ip" {
  value = aws_eip.eip.public_ip
}
output "ec2_instance_id" {
  value = aws_instance.ec2.id
}
output "ec2_sg_id" {
  value = aws_security_group.ec2
}
output "rds_sg_id" {
  value = aws_security_group.rds
}