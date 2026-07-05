terraform {
  required_version = ">= 1.13"

  backend "s3" {
    bucket       = "coraline-metabase-tfstate"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
    profile      = "coraline-iac"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28" # required by vpc 6.6 / rds 7.x / alb 10.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  name = "coraline-metabase"
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project   = local.name
      ManagedBy = "terraform"
    }
  }
}
