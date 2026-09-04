variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "eu-central-1"
}

variable "trusted_ip" {
  description = "Public IPv4 address allowed to connect over SSH"
  type        = string
}

