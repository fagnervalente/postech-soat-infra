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

data "aws_eks_cluster" "target_eks" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "target_eks_auth" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.target_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.target_eks_auth.token
}

resource "kubernetes_config_map_v1_data" "delivery-configmap" {
  metadata {
    name = "delivery-configmap"
  }

  force = true

  data = {
    DATABASE_HOST     = "${aws_db_instance.delivery.address}"
    DATABASE_NAME     = "${aws_db_instance.delivery.db_name}"
    DATABASE_PORT     = "${aws_db_instance.delivery.port}"
    DATABASE_USER     = "${aws_db_instance.delivery.username}"
    DATABASE_PASSWORD = "${aws_db_instance.delivery.password}"
    SERVER_PORT       = "3000"
  }
}
