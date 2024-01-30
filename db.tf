provider "mongodbatlas" {
  public_key = ""
  private_key  = ""
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "delivery_db_subnet"
  subnet_ids = aws_subnet.public_subnets[*].id

  tags = {
    Name = "Delivery"
  }
}

# Create a security group in the VPC to which the database will belong
resource "aws_security_group" "delivery_rds" {
  name   = "delivery_rds"
  vpc_id = aws_vpc.delivery_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a random password
resource "random_string" "uddin-db-password" {
  length  = 32
  upper   = true
  special = false
}

# Configure database instance
resource "aws_db_instance" "delivery_db" {
  identifier             = "delivery-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = "postgres"
  password               = random_string.uddin-db-password.result
  db_name                = "delivery"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.delivery_rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}
