#DATA SOURCES----------------------------------------------------
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "maksym-kowalski-projectautodeploy-tfstate"
    key    = "global/terraform.tfstate"
    region = "ca-central-1"
  }
}
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
data "aws_region" "current" {}
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

amazon-linux-extras install postgresql14 -y
SECRET=$(aws secretsmanager get-secret-value \
--secret-id ${aws_secretsmanager_secret.rds_secret.name} \
--region ${data.aws_region.current.id} \
--query SecretString \
--output text)

echo $SECRET > /home/ec2-user/db-credentials.txt
chown ec2-user:ec2-user /home/ec2-user/db-credentials.txt
EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-ec2"
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
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

#RANDOM PASSWORD-------------------------------------
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
#RANDOM PASSWORD-------------------------------------

#DB-SUBNET-GROUP-------------------------------------
resource "aws_db_subnet_group" "rds" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "${var.project_name}-${var.environment}-rds-subnet-group"
  }
}
#DB-SUBNET-GROUP-------------------------------------

#SECRETS-MANAGER-------------------------------------
resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "${var.project_name}_${var.environment}_rds-secret"
  description             = "RDS master credentials"
  recovery_window_in_days = 0
  tags = {
    Name = "${var.project_name}-${var.environment}-rds-secret"
  }
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.arn
  secret_string = jsonencode({
    username : var.db_username
    password : random_password.db_password.result
    db_name : var.db_name
  })
}
#SECRETS-MANAGER-------------------------------------

#IAM-ROLE-FOR-EC2------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
    }
  )
}
resource "aws_iam_role_policy_attachment" "ec2_secrets_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
#IAM-ROLE-FOR-EC2------------------------------------

#RDS-------------------------------------------------
resource "aws_db_instance" "rds" {
  identifier              = lower(replace("${var.project_name}-${var.environment}-rds", "_", "-"))
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = var.db_instance_type
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = var.multi_az
  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = false
  backup_retention_period = 0
  tags = {
    Name = "${var.project_name}-${var.environment}-rds"
  }
}
#RDS----------------------------------------------------