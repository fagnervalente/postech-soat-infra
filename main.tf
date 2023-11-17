# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Configure AWS Provider
provider "aws" {
  region = var.region
}

locals {
  cluster_name = "delivery-eks"
}

# Create a VPC
resource "aws_vpc" "delivery_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "deliveryVPC"
  }
}

# Create an Internet gateway to give our subnet access to the outside world:
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.delivery_vpc.id

  tags = {
    Name = "delivery-gateway"
  }
}

# Grant Internet access to the VPC in your primary route table:
resource "aws_route" "route" {
  route_table_id         = aws_vpc.delivery_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# Get Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create subnets in each Availability Zone to launch our instances, each with address blocks within the VPC:
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id     = aws_vpc.delivery_vpc.id
  cidr_block = "10.0.${count.index}.0/24"

  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "public-${element(data.aws_availability_zones.available.names, count.index)}"

    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  map_public_ip_on_launch = true
}

# Create a security group in the VPC which our instances will belong to
resource "aws_security_group" "default" {
  name        = "delivery_security_group"
  description = "Terraform example security group"
  vpc_id      = aws_vpc.delivery_vpc.id

  # Allow outbound internet access.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "delivery-security-group"
  }
}

# IAM Role for EKS
resource "aws_iam_role" "EKSClusterRole" {
  name = "EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Role for Kubernetes
resource "aws_iam_role" "NodeGroupRole" {
  name = "EKSNodeGroupRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Policy required for EKS

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.EKSClusterRole.name
}

# Policies required for Kubernetes
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}

# Create Cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.28"

  vpc_id                         = aws_vpc.delivery_vpc.id
  subnet_ids                     = aws_subnet.public_subnets[*].id
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  aws_auth_roles = [
    aws_iam_role.EKSClusterRole,
    aws_iam_role.NodeGroupRole
  ]
}
