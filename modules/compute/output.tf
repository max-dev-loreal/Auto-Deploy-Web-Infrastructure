output "alb_dns_name" {
  value = aws_lb.tg.dns_name
}
output "alb_arn" {
  value = aws_lb.tg.arn
}
output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
output "ec2_sg_id" {
  value = aws_security_group.ec2.id
}
output "rds_sg_id" {
  value = aws_security_group.rds.id
}