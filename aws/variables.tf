# AWS Region
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# AWS Availability Zone
variable "aws_az" {
  description = "AWS Availability Zone for subnet"
  type        = string
  default     = "us-east-1a"
}

# AWS Access Key
variable "aws_access_key" {
  description = "AWS Access Key for authentication"
  type        = string
}

# AWS Secret Key
variable "aws_secret_key" {
  description = "AWS Secret Key for authentication"
  type        = string
}

# EC2 AMI ID
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 (Update as needed)
}

# SSH Key Name
variable "ssh_key_name" {
  description = "Name of the SSH key pair to access EC2 instance"
  type        = string
}

# Enable Load Balancer
variable "enable_lb" {
  description = "Enable Load Balancer (true/false)"
  type        = bool
  default     = false
}
