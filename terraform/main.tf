terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "cloud-engineering"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "terraform_lab" {
  name        = "terraform-cloud-engineering-lab"
  description = "Security group managed by Terraform for cloud engineering lab"

  ingress {
    description = "SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "terraform-cloud-engineering-lab"
    Project = "cloud-engineering-api"
  }
}

resource "aws_instance" "terraform_lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "cloud-engineering-lab-key"
  vpc_security_group_ids = [aws_security_group.terraform_lab.id]

  tags = {
    Name    = "terraform-cloud-engineering-ec2"
    Project = "cloud-engineering-api"
  }
}