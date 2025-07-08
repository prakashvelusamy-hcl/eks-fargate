
resource "random_password" "db_password" {
  length  = 16
  special = true
}

#########################
# RDS Security Group
#########################
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow access from EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#########################
# RDS Subnet Group
#########################
resource "aws_db_subnet_group" "db" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "db-subnet-group"
  }
}

#########################
# RDS Instance
#########################
resource "aws_db_instance" "default" {
  identifier             = "my-rds-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  username               = "admin"
  password               = random_password.db_password.result
  db_name                = "employees"
  skip_final_snapshot    = true
  publicly_accessible    = false
  apply_immediately      = true
  multi_az               = false

  tags = {
    Name = "rds-instance"
  }
}

#########################
# Secret 1: Credentials (username/password)
#########################
resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "rds-credentials-secret1"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}

#########################
# Secret 2: Connection Info (host/dbname)
#########################
resource "aws_secretsmanager_secret" "rds_connection" {
  name = "rds-connection-secret1"
}

resource "aws_secretsmanager_secret_version" "rds_connection" {
  secret_id = aws_secretsmanager_secret.rds_connection.id
  secret_string = jsonencode({
    host   = aws_db_instance.default.address
    port   = 3306
    dbname = "employees"
    engine = "mysql"
  })
}
