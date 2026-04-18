terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    random = {
      source = "hashicorp/random"
    }

  }
  backend "s3" {
    bucket         = "maksym-kowalski-projectautodeploy-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}





provider "aws" {
  region = var.region
}
provider "random" {}