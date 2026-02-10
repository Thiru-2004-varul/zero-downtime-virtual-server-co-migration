resource "aws_internet_gateway" "vmcm_igw" {
    vpc_id = aws_vpc.vmcm_vpc.id

    tags = {
      name ="vmcm-igw"
    }
}