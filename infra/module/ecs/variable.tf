variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_image" {
  description = "Full ECR image URI with tag"
  type        = string
}

variable "container_port" {
  type    = number
  default = 80
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
