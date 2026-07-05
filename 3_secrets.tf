resource "random_password" "db" {
  length  = 32
  special = true
  # Exclude characters RDS forbids in a master password ( / @ " and space ).
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Optional: Metabase uses this to encrypt saved data-source credentials & secrets at rest.

resource "random_password" "mb_encryption_key" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.name}/db-password"
  description = "Metabase RDS master password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

resource "aws_secretsmanager_secret" "mb_encryption_key" {
  name        = "${local.name}/encryption-key"
  description = "Metabase MB_ENCRYPTION_SECRET_KEY"
}

resource "aws_secretsmanager_secret_version" "mb_encryption_key" {
  secret_id     = aws_secretsmanager_secret.mb_encryption_key.id
  secret_string = random_password.mb_encryption_key.result
}
