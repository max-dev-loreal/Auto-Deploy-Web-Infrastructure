data "aws_availability_zones" "azs" {
  state = "available"
}
#VPC--------------------------------------------------------------
resource "aws_vpc" "my_aws_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}
#VPC--------------------------------------------------------------
#PUBLIC-SUBNETS-----------------------------------------------------------
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-2"
  }
}
#PUBLIC-SUBNETS-----------------------------------------------------------
#PRIVATE-SUBNETS-----------------------------------------------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-2"
  }
}
#PRIVATE-SUBNETS-----------------------------------------------------------
#IGW-------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_aws_vpc.id
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}
#IGW-------------------------------------------------------
#ROUTE-TABLES----------------------------------------------

#PUBLIC-RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_aws_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}
#PUBLIC-RT

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

#PRIVATE-RT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_aws_vpc.id
  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}
#PRIVATE-RT

resource "aws_route_table_association" "private_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}

#ROUTE-TABLES----------------------------------------------
