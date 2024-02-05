data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_docdb_subnet_group" "docdb_subnet_group" {
  name       = "my-docdb-subnet-group"
  subnet_ids = data.aws_subnets.all.ids

  tags = {
    Name = "my-docdb-subnet-group"
  }
}

resource "aws_security_group" "delivery_docdb" {
  name   = "delivery_docdb"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "docdb-cluster-demo-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "delivery-docdb-cluster"
  master_username         = "docdb"
  master_password         = random_string.uddin-db-password.result
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.docdb_subnet_group.name
  apply_immediately = true
  engine      = "docdb"
  engine_version = "3.6.0"
  storage_encrypted = true
  
  vpc_security_group_ids = [aws_security_group.delivery_docdb.id]

  tags = {
    Name = "delivery-docdb-cluster"
  }
}

