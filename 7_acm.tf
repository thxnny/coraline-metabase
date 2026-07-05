# ACM certificate for the Metabase hostname, DNS-validated.
#
# The domain is managed OUTSIDE Route53, so Terraform cannot create the
# validation record. Flow:
#   1. terraform apply -target=aws_acm_certificate.metabase
#   2. terraform output acm_validation_records  -> add that CNAME at your DNS
#      provider (DNS-only / not proxied), then wait for ACM to issue it
#   3. terraform apply  -> the validation resource below unblocks and the ALB
#      443 listener attaches the now-ISSUED cert
resource "aws_acm_certificate" "metabase" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Blocks dependent resources (the ALB HTTPS listener) until the certificate is
# actually ISSUED. Because the DNS record is added by hand at an external
# provider, `terraform apply` waits here (up to the validation timeout) rather
# than failing when the listener references a not-yet-issued cert.
resource "aws_acm_certificate_validation" "metabase" {
  certificate_arn = aws_acm_certificate.metabase.arn
}
