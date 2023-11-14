resource "aws_db_subnet_group" "delivery" {
  name       = "delivery"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "Delivery"
  }
}

resource "aws_security_group" "rds" {
  name   = "delivery_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "delivery_rds"
  }
}

resource "aws_db_parameter_group" "delivery" {
  name   = "delivery"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "random_string" "uddin-db-password" {
  length  = 32
  upper   = true
  special = false
}

resource "aws_db_instance" "delivery" {
  identifier             = "delivery"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = "postgres"
  password               = random_string.uddin-db-password.result
  db_name                = "delivery"
  db_subnet_group_name   = aws_db_subnet_group.delivery.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.delivery.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
