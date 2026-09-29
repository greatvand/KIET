output "secret_name" {
  value = aws_secretsmanager_secret.db_secret.name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "database_name" {
  value = aws_db_instance.postgres_db.db_name
}

output "db_username" {
  value = var.db_username
}