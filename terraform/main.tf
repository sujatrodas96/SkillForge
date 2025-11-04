resource "aws_instance" "skillforge_app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  tags = {
    Name = "SkillForgeApp"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    docker pull ${var.docker_image}
    docker run -d -p 80:80 --name skillforge ${var.docker_image}
  EOF
}
