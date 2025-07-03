# Base de données RDS
resource "aws_db_subnet_group" "default" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [subnet_ids]
  }
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small"
  identifier             = "${var.project}-db"
  db_name                = "appdb"
  
  # Gestion automatique des credentials par AWS Secrets Manager
  manage_master_user_password = true
  username = var.db_username
  
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = true

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}