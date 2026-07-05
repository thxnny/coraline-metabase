# Security group chain that enforces the core requirement:
#   internet -> alb_sg (created by the ALB module) -> ecs_sg -> rds_sg
# RDS accepts traffic ONLY from the Metabase tasks; nothing from the internet.

# --- ECS task security group -------------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs"
  description = "Metabase Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "${local.name}-ecs" }
}

# Only the ALB may reach the Metabase container port.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Metabase HTTP from ALB"
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}

# Tasks need outbound to pull the image (via NAT) and reach RDS.
resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "All egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- RDS security group ------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Metabase PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "${local.name}-rds" }
}

# Postgres reachable ONLY from the ECS tasks — no CIDR, no internet.
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from Metabase tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "All egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
