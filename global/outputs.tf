output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.id
}
output "project_name" {
  value     = aws_ssm_parameter.projectname.value
  sensitive = true
}
output "region" {
  value     = aws_ssm_parameter.environment_region.value
  sensitive = true
}