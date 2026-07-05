resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "metabase" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.metabase_cpu
  memory                   = var.metabase_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "metabase"
      image     = var.metabase_image
      essential = true

      portMappings = [
        { containerPort = 3000, protocol = "tcp" }
      ]

      environment = [
        { name = "MB_DB_TYPE", value = "postgres" },
        { name = "MB_DB_DBNAME", value = var.db_name },
        { name = "MB_DB_HOST", value = module.rds.db_instance_address },
        { name = "MB_DB_PORT", value = "5432" },
        { name = "MB_DB_USER", value = var.db_username },
        { name = "JAVA_TIMEZONE", value = "UTC" },
      ]

      secrets = [
        { name = "MB_DB_PASS", valueFrom = aws_secretsmanager_secret.db_password.arn },
        { name = "MB_ENCRYPTION_SECRET_KEY", valueFrom = aws_secretsmanager_secret.mb_encryption_key.arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.metabase.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "metabase"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "metabase" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.metabase.arn
  desired_count   = var.metabase_desired_count
  launch_type     = "FARGATE"

  # Metabase runs DB migrations on first boot and is slow to become healthy;
  # a generous grace period avoids a crash loop of killed-before-ready tasks.
  health_check_grace_period_seconds = 300

  enable_execute_command = true # for the private-DB negative test

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false # tasks have no public IP; egress via NAT only
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["metabase"].arn
    container_name   = "metabase"
    container_port   = 3000
  }

  depends_on = [module.alb]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
