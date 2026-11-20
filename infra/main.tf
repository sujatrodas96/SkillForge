terraform {
  required_version = ">= 1.5.7"
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

locals {
  common_tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "my-app-repo"
  tags            = local.common_tags
}

module "ecs" {
  source          = "./modules/ecs"
  cluster_name    = "my-app-cluster"
  service_name    = "my-app-service"
  container_image = "${module.ecr.repository_url}:${var.image_tag}"
  container_port  = 80
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  tags            = local.common_tags
}
