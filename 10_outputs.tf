output "metabase_url" {
  description = "URL Metabase will be served on once DNS is pointed at the ALB."
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "ALB hostname. Create a CNAME for your domain -> this value (DNS-only)."
  value       = module.alb.dns_name
}

output "acm_validation_records" {
  description = "Add these CNAME record(s) at your external DNS provider to validate the ACM cert."
  value = [
    for o in aws_acm_certificate.metabase.domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate (check status with `aws acm describe-certificate`)."
  value       = aws_acm_certificate.metabase.arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint (private — not reachable from the internet)."
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS cluster name (for `aws ecs execute-command`)."
  value       = aws_ecs_cluster.this.name
}
