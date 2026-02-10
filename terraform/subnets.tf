data "aws_availability_zones" "available" {
  state = "available"
}





resource "aws_subnet" "public_subnets" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.vmcm_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "vmcm-public-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = var.subnet_count
  vpc_id            = aws_vpc.vmcm_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "vmcm-private-${count.index}"
  }
}
