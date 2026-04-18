terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = "~> 1.14"
  backend "s3" {
    bucket         = "maksym-kowalski-projectautodeploy-tfstate"
    key            = "global/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
provider "aws" {
  region = "ca-central-1"
}
