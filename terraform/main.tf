provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "skillforge_app" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name      = var.key_name

  tags = {
    Name = "SkillForge"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo docker run -d -p 80:80 sujatro123/skillforge:latest
  EOF
}

variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}
