terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "monitoring-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "monitoring_igw" {
  vpc_id = aws_vpc.monitoring_vpc.id

  tags = {
    Name = "monitoring-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "monitoring_public_subnet" {
  vpc_id                  = aws_vpc.monitoring_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "monitoring-public-subnet"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "monitoring_public_rt" {
  vpc_id = aws_vpc.monitoring_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitoring_igw.id
  }

  tags = {
    Name = "monitoring-public-rt"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "monitoring_public_rta" {
  subnet_id      = aws_subnet.monitoring_public_subnet.id
  route_table_id = aws_route_table.monitoring_public_rt.id
}

# Get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create AWS key pair from your existing public key
resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  # For Windows, use the full path to your public key
  public_key = file("C:/Users/USER/.ssh/id_rsa.pub")
}

# Create a security group allowing necessary ports
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-stack-sg"
  description = "Security group for monitoring stack"
  vpc_id      = aws_vpc.monitoring_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # My WebApp
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-stack-sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "monitoring_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.monitoring_public_subnet.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name  # Reference the key we created

  # Use the user data script to install and configure everything
  user_data = filebase64("${path.module}/user-data.sh")

  tags = {
    Name = "monitoring-stack"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

# Create an Elastic IP for the instance
resource "aws_eip" "monitoring_eip" {
  instance = aws_instance.monitoring_server.id
  domain  =  "vpc"
}
