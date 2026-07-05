module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name    = local.name
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  internal                   = false # internet-facing
  enable_deletion_protection = false

  # Module-managed ALB security group (this is `alb_sg` in the plan).
  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # :80 redirects to :443; :443 terminates TLS with the ACM cert and forwards
  # to Metabase. The certificate must be ISSUED (add the ACM validation CNAME at
  # your DNS provider) for the apply to complete.
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port     = 443
      protocol = "HTTPS"
      # Reference the validation resource (not the cert directly) so the
      # listener is created only after the cert is ISSUED.
      certificate_arn = aws_acm_certificate_validation.metabase.certificate_arn
      forward = {
        target_group_key = "metabase"
      }
    }
  }

  target_groups = {
    metabase = {
      name_prefix = "mb-"
      protocol    = "HTTP"
      port        = 3000
      target_type = "ip" # Fargate awsvpc registers task ENIs by IP

      # ECS registers/deregisters targets itself.
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/api/health"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 5
      }

      deregistration_delay = 30
    }
  }
}
