output "ec2_public_ip" {
  description = "Public IP of the deployed EC2 instance"
  value       = aws_instance.skillforge_app.public_ip
}
