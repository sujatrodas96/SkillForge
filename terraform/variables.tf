variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "Amazon Machine Image ID (Ubuntu 22.04 for us-east-1)"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc" # ✅ Ubuntu 22.04 LTS in North Virginia
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = "data-drive"
}

variable "docker_image" {
  description = "Docker image name to deploy"
  type        = string
}