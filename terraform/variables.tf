

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

# ──  EKS variables ────────────────────────────────────────

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "vmcm-eks"
}

variable "eks_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS managed nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "Minimum EKS worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max" {
  description = "Maximum EKS worker nodes"
  type        = number
  default     = 4
}

# ──  ECR variables ────────────────────────────────────────

variable "ecr_repo_name" {
  description = "ECR repository name for the mobile app"
  type        = string
  default     = "mobile-app"
}