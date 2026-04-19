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
  subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]
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
  vpc_security_group_ids = [var.rds_sg_id]
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