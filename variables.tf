variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-southeast-2"
}

variable "availability_zone_1" {
  description = "First Availability Zone"
  type        = string
  default     = "ap-southeast-2a"
}

variable "availability_zone_2" {
  description = "Second Availability Zone"
  type        = string
  default     = "ap-southeast-2b"
}

variable "project_name" {
  description = "Name used for resources created by this project"
  type        = string
  default     = "auto-healing"
}

variable "instance_type" {
  description = "EC2 instance type for the web servers"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}