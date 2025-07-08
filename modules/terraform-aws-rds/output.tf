output "credentials_secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "connection_secret_arn" {
  value = aws_secretsmanager_secret.rds_connection.arn
}

output "db_host" {
  value = aws_db_instance.default.address
}
