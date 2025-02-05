provider "aws" {
  region = var.aws_region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# VPC (Virtual Network in AWS)
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cloud-vpc"
  }
}

# Subnet for Web/App/DB
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.aws_az

  tags = {
    Name = "webappdb-subnet"
  }
}

# Security Group (NSG in Azure)
resource "aws_security_group" "sg" {
  name        = "cloud-sg"
  description = "Security group for web VM"
  vpc_id      = aws_vpc.vpc.id

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-security-group"
  }
}

# Elastic IP (Public IP in AWS)
resource "aws_eip" "eip" {
  vpc = true
}

# Network Interface (ENI)
resource "aws_network_interface" "web_nic" {
  subnet_id   = aws_subnet.subnet.id
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "web-nic"
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "aws-key"
  public_key = file("aws-key.pub")
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web_vm" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key.key_name

  tags = {
    Name = "web-vm"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }
}

# Elastic Load Balancer (Optional, for horizontal scaling)
resource "aws_lb" "lb" {
  count   = var.enable_lb ? 1 : 0
  name    = "cloud-lb"
  internal = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets           = [aws_subnet.subnet.id]

  tags = {
    Name = "cloud-lb"
  }
}

