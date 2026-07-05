data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Three isolated tiers carved out of the VPC CIDR:
  #   public   -> ALB + NAT gateway          (routes to Internet Gateway)
  #   private  -> ECS Fargate tasks          (egress via NAT only)
  #   database -> RDS PostgreSQL             (no internet route at all)
  public_subnets   = [for i in range(var.az_count) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_subnets  = [for i in range(var.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 10)]
  database_subnets = [for i in range(var.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 20)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  # Dedicated, isolated subnet group for RDS.
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false # DB tier must NOT reach the internet

  # Single NAT keeps cost down; set false-per-AZ for prod HA if desired.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
