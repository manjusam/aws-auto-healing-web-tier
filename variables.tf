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