terraform {
  # use_lockfile (native S3 locking, no DynamoDB) needs Terraform >= 1.10
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }

  # Must match the name the pipeline computes: tfstate-<account-id>-<region>
  state_bucket_name = "tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

# Remote state bucket (used by the backend in backend.tf)
module "s3" {
  source      = "./module/s3"
  bucket_name = local.state_bucket_name
  tags        = merge(local.common_tags, { Purpose = "terraform-state" })
}

module "ecr" {
  source          = "./module/ecr"
  repository_name = "my-app-repo"
  tags            = local.common_tags
}

module "ecs" {
  source          = "./module/ecs"
  cluster_name    = "my-app-cluster"
  service_name    = "my-app-service"
  container_image = "${module.ecr.repository_url}:${var.image_tag}"
  container_port  = 80
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  tags            = local.common_tags
}