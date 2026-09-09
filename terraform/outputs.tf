output "vpc_id" {
  description = "ID of the Terraform-managed VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "terraform_lab_public_ip" {
  description = "Public IPv4 address of the Terraform-managed EC2 instance"
  value       = aws_instance.terraform_lab.public_ip
}

output "terraform_lab_private_ip" {
  description = "Private IPv4 address of the Terraform-managed EC2 instance"
  value       = aws_instance.terraform_lab.private_ip
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "private_instance_private_ip" {
  description = "Private IP address of the EC2 instance in the private subnet"
  value       = aws_instance.private_lab.private_ip
}

output "private_instance_id" {
  description = "ID of the EC2 instance in the private subnet"
  value       = aws_instance.private_lab.id
}