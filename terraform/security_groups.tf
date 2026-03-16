resource "aws_security_group" "alb_sg" {
  name        = "vmcm-alb-sg"
  description = "Allow HTTP to ALB"
  vpc_id      = aws_vpc.vmcm_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vmcm-alb-sg"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "vmcm-bastion-sg"
  description = "Allow SSH only from my Kali machine"
  vpc_id      = aws_vpc.vmcm_vpc.id

  ingress {
    description = "SSH from Kali public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["157.49.107.250/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vmcm-bastion-sg"
  }
}


resource "aws_security_group" "private_ec2_sg" {
  name        = "vmcm-private-ec2-sg"
  description = "Allow SSH only from bastion host"
  vpc_id      = aws_vpc.vmcm_vpc.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Kubernetes NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vmcm_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vmcm-private-ec2-sg"
  }
}

resource "aws_security_group_rule" "k8s_api" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.private_ec2_sg.id
  description       = "Kubernetes API server"
}

resource "aws_security_group_rule" "k8s_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.private_ec2_sg.id
  security_group_id        = aws_security_group.private_ec2_sg.id
  description              = "Allow all internal K8s traffic"
}

resource "aws_security_group_rule" "alb_to_nodeport" {
  type                     = "ingress"
  from_port                = 30007
  to_port                  = 30007
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.private_ec2_sg.id
  description              = "ALB to K8s NodePort"
}

resource "aws_security_group_rule" "alb_grafana_inbound" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Grafana inbound"
}


resource "aws_security_group_rule" "alb_prometheus_inbound" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Prometheus inbound"
}


resource "aws_security_group_rule" "alb_to_grafana_nodeport" {
  type                     = "ingress"
  from_port                = 30030
  to_port                  = 30030
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.private_ec2_sg.id
  description              = "ALB to Grafana NodePort"
}


resource "aws_security_group_rule" "alb_to_prometheus_nodeport" {
  type                     = "ingress"
  from_port                = 30090
  to_port                  = 30090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.private_ec2_sg.id
  description              = "ALB to Prometheus NodePort"
}