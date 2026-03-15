resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vmcm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vmcm_igw.id
  }
  tags = {
    Name = "vmcm-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vmcm_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vmcm_nat.id
  }
  tags = {
    Name = "vmcm-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
