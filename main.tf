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

#SECURITY-GROUPS-------------------------------------------
resource "aws_security_group" "ec2" {
  vpc_id = aws_vpc.my_aws_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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

#SG FOR ALB-------------------------------------------------
resource "aws_security_group" "alb" {
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#SG FOR ALB----------------------------------------------------

#ALB--------------------------------------------------
resource "aws_lb" "tg" {
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  enable_deletion_protection = false
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}
#ALB--------------------------------------------------


#TARGET GROUP--------------------------------------------------
resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_aws_vpc.id
  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}
#TARGET GROUP--------------------------------------------------

#LISTENER------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.tg.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
#LISTENER-------------------------------------------------------

#LAUNCH TEMPLATE------------------------------------------------
resource "aws_launch_template" "lt" {
  name_prefix            = "${var.project_name}-${var.environment}-lt-"
  image_id               = data.aws_ami.amazon_linux_latest.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y 
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx
echo "<h1>Hello from $(hostname)</h1>" > /usr/share/nginx/html/index.html
EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
  }
}
#LAUNCH TEMPLATE------------------------------------------------

#ASG------------------------------------------------
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.project_name}-${var.environment}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-ec2"
    propagate_at_launch = true
  }
}
#ASG------------------------------------------------