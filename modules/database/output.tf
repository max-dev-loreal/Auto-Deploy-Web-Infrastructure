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
output "secret_name" {
  value = aws_secretsmanager_secret.rds_secret.name
}