resource "aws_vpc" "vpc" {
  cidr_block           = "172.32.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

data "aws_availability_zones" "az_available" {
  state                  = "available"
  all_availability_zones = true
}

resource "aws_subnet" "public_subnet" {
  for_each = toset(data.aws_availability_zones.az_available.names)

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value
  cidr_block = cidrsubnet(
    aws_vpc.vpc.cidr_block,
    8,
    index(data.aws_availability_zones.az_available.names, each.value)
  )
  map_public_ip_on_launch = true

  tags = local.common_tags

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = local.common_tags
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = local.common_tags

}

resource "aws_route_table_association" "public_subnet_route_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id

}