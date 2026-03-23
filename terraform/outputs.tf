output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vmcm_vpc.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.vmcm_eks.name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.vmcm_eks.endpoint
}

output "eks_oidc_issuer" {
  description = "EKS OIDC issuer URL"
  value       = aws_eks_cluster.vmcm_eks.identity[0].oidc[0].issuer
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "mobile_app_irsa_role_arn" {
  description = "IRSA role ARN for mobile-app pods"
  value       = aws_iam_role.mobile_app_irsa.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repository_url" {
  description = "ECR repo URL"
  value       = aws_ecr_repository.mobile_app.repository_url
}

output "kubeconfig_command" {
  description = "Run this after terraform apply to configure kubectl"
  value       = "aws eks update-kubeconfig --region ap-south-1 --name ${aws_eks_cluster.vmcm_eks.name}"
}

output "ssm_connect_note" {
  description = "How to connect to EKS nodes"
  value       = "AWS Console → EC2 → select node → Connect → Session Manager"
}