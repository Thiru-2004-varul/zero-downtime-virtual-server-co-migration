


resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.cluster_name}-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── EKS Cluster ──────────────────────────────────────────────

resource "aws_eks_cluster" "vmcm_eks" {
  name     = var.cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.private_subnets[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = [
    "api", "audit", "authenticator",
    "controllerManager", "scheduler"
  ]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  tags = { Name = var.cluster_name }
}

# ── IAM Role for EKS Worker Nodes ────────────────────────────

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.cluster_name}-node-role" }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── EKS Managed Node Group ────────────────────────────────────

resource "aws_eks_node_group" "vmcm_nodes" {
  cluster_name    = aws_eks_cluster.vmcm_eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids     = aws_subnet.private_subnets[*].id
  instance_types = [var.eks_node_instance_type]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = var.eks_node_desired
    min_size     = var.eks_node_min
    max_size     = var.eks_node_max
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role    = "worker"
    project = "vmcm"
  }

  tags = { Name = "${var.cluster_name}-node-group" }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_read,
    aws_iam_role_policy_attachment.eks_ssm_policy,
  ]
}