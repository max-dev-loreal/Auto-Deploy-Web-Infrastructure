variable "region" {
  type    = string
  default = "eu-north-1"
}
variable "project_name" {
  type    = string
  default = "Auto-Deploy-WebApplication-on-AWS"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}
variable "private_subnet_1_cidr" {
  type    = string
  default = "10.0.3.0/24"
}
variable "private_subnet_2_cidr" {
  type    = string
  default = "10.0.4.0/24"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "your_ip" {
  description = "Enter your ip address for access"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/32$", var.your_ip))
    error_message = "The value must be in the format x.x.x.x/32 (e.g. 1.2.3.4/32)."
  }
}
