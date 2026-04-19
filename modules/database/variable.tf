variable "vpc_id" {
  type = string
}
variable "private_subnet_1_id" {
  type = string
}
variable "private_subnet_2_id" {
  type = string
}
variable "ec2_sg_id" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_username" {
  type = string
}
variable "db_instance_type" {
  type = string
}
variable "db_allocated_storage" {
  type = number
}
variable "multi_az" {
  type = bool
}
variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "rds_sg_id" {
  type = string
}