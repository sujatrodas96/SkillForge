# Security Group for SkillForge EC2
resource "aws_security_group" "skillforge_sg" {
  name        = "skillforge-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "skillforge-sg"
  }
}

# Get default VPC for security group
data "aws_vpc" "default" {
  default = true
}

# Attach this SG to your instance
resource "aws_instance" "skillforge_app" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t3.micro"
  key_name      = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.skillforge_sg.id]

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
