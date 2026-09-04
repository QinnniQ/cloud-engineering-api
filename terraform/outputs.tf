output "terraform_lab_public_ip" {
  description = "Public IPv4 address of the Terraform-managed EC2 instance"
  value       = aws_instance.terraform_lab.public_ip
}