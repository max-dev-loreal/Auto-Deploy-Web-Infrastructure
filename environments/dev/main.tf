#DATA SOURCES----------------------------------------------------
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "maksym-kowalski-projectautodeploy-tfstate"
    key    = "global/terraform.tfstate"
    region = "ca-central-1"
  }
}
#DATA SOURCES----------------------------------------------------
module "networking" {
  source                = "../../modules/networking"
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  project_name          = var.project_name
  environment           = var.environment
}
module "database" {
  source = "../../modules/database"

  vpc_id               = module.networking.vpc_id
  private_subnet_1_id  = module.networking.private_subnet_1_id
  private_subnet_2_id  = module.networking.private_subnet_2_id
  ec2_sg_id            = module.compute.ec2_sg_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_instance_type     = var.db_instance_type
  db_allocated_storage = var.db_allocated_storage
  multi_az             = var.multi_az
  project_name         = var.project_name
  environment          = var.environment
  rds_sg_id            = module.compute.rds_sg_id
}
module "compute" {
  source = "../../modules/compute"

  vpc_id             = module.networking.vpc_id
  public_subnet_1_id = module.networking.public_subnet_1_id
  public_subnet_2_id = module.networking.public_subnet_2_id
  instance_type      = var.instance_type
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  project_name       = var.project_name
  environment        = var.environment
  your_ip            = var.your_ip
  secret_arn         = module.database.secret_arn
  public_key_path    = "${path.module}/my-project-key.pub"
  secret_name        = module.database.secret_name
  region             = var.region
}
#FINAL TEST CI/CD PIPELINE