variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL to clone"
  type        = string
  default     = "https://github.com/GfavourBraimah/Monitoring_app"
}

