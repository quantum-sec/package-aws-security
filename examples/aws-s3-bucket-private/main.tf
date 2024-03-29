terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.29"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "aws_s3_bucket_private" {
  source = "../../modules/aws-s3-private"

  bucket_name     = format("example-%s-%s", data.aws_caller_identity.current.account_id, var.name)
  logging_enabled = var.enable_logging
  tags            = var.tags
}

data "aws_caller_identity" "current" {
}
