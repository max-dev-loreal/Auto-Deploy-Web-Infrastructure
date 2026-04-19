variable "vpc_id" {
  type = string
}
variable "public_subnet_1_id" {
  type = string
}
variable "public_subnet_2_id" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "min_size" {
  type = number
}
variable "max_size" {
  type = number
}
variable "desired_capacity" {
  type = number
}
variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "your_ip" {
  type = string
}
variable "secret_arn" {
  type = string
}
variable "public_key_path" {
  type = string
}
variable "secret_name" {
  type = string
}
variable "region" {
  type = string
}