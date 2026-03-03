data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "k8s_nodes" {
  count                       = var.k8s_node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.private_subnets[count.index % length(aws_subnet.private_subnets)].id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.private_ec2_sg.id]

  user_data = count.index == 0 ? file("${path.module}/../scripts/master-init.sh") : file("${path.module}/../scripts/worker-init.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = count.index == 0 ? "vmcm-k8s-master" : "vmcm-k8s-worker-${count.index}"
    Role = count.index == 0 ? "master" : "worker"
  }
}
