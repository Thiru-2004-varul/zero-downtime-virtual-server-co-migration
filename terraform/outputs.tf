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

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.k8s_nodes[*].id
}

output "alb_dns_name" {
  description = "ALB DNS endpoint"
  value       = aws_lb.vmcm_alb.dns_name
}
