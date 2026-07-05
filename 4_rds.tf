module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = local.name

  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  manage_master_user_password = false
  password_wo                 = random_password.db.result
  password_wo_version         = 1

  multi_az               = false
  publicly_accessible    = false # <-- database is never internet-reachable
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  deletion_protection     = false # prod: true — false here because this is only a test
  skip_final_snapshot     = true  # prod: false — true here because this is only a test

  performance_insights_enabled = false
  create_monitoring_role       = false
}
