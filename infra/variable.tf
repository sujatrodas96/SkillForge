variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ECS tasks"
  type        = list(string)
}

variable "image_tag" {
  type    = string
  default = "latest"
}
