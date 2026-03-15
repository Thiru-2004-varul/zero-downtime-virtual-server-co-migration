variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "Base CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of AZs / subnet pairs"
  default     = 2
}

variable "instance_type" {
  default = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "k8s_node_count" {
  description = "Total Kubernetes nodes (1 master + workers)"
  type        = number
  default     = 3
}
