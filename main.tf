#DATA SOURCES----------------------------------------------------
data "aws_availability_zones" "azs" {
  state = "available"
}
data "aws_ami" "amazon_linux_latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
#DATA SOURCES----------------------------------------------------




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
  route_table_id = aws_internet_gateway.igw.id
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

#SECURITY-GROUPS-------------------------------------------
resource "aws_security_group" "ec2" {
  vpc_id = aws_vpc.my_aws_vpc.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = tonumber(ingress.value)
      to_port     = tonumber(ingress.value)
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.my_aws_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}
#SECURITY-GROUPS-------------------------------------------

#KEY-PAIR--------------------------------------------------
resource "aws_key_pair" "public_key" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file("${path.module}/my-project-key.pub")
}
#KEY-PAIR---------------------------------------------------

#{EC2------------------------------------------------------}
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.amazon_linux_latest.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.public_key.key_name
  user_data              = <<-EOF
#!/bin/bash
yum update -y 
yum install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Hello from $(hostname)</h1>" > /usr/share/nginx/html/index.html
EOF
  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
}
#{EC2----------------------------------------------------------}

#EIP
resource "aws_eip" "eip" {
  domain     = "vpc"
  instance   = aws_instance.ec2.id
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }
}
#EIP
