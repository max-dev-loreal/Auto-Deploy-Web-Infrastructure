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
#SECURITY-GROUPS-------------------------------------------
resource "aws_security_group" "ec2" {
  vpc_id = var.vpc_id

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
resource "aws_security_group" "alb" {
  vpc_id = var.vpc_id
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
#SECURITY-GROUPS-------------------------------------------
#KEY-PAIR--------------------------------------------------
resource "aws_key_pair" "public_key" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file("${path.root}/${var.public_key_path}")
}
#KEY-PAIR---------------------------------------------------
#ALB--------------------------------------------------
resource "aws_lb" "tg" {
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [var.public_subnet_1_id, var.public_subnet_2_id]
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
  vpc_id   = var.vpc_id
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
--secret-id ${var.secret_name} \
--region ${var.region} \
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
  vpc_zone_identifier       = [var.public_subnet_1_id, var.public_subnet_2_id]
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
resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id

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
#GITHUB EBEANAT
