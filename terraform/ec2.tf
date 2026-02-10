data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
resource "aws_instance" "k8s_nodes" {
  count         = var.subnet_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "vmcm-k8s-node-${count.index}"
  }
}
