data "aws_eks_cluster" "target_eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "target_eks_auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.target_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.target_eks_auth.token
}

# Create configMap with the variables necessary for the application
resource "kubernetes_config_map" "delivery-configmap" {
  metadata {
    name = "delivery-configmap"
  }

  data = {
    DATABASE_HOST     = "${aws_db_instance.delivery_db.address}"
    DATABASE_NAME     = "${aws_db_instance.delivery_db.db_name}"
    DATABASE_PORT     = "${aws_db_instance.delivery_db.port}"
    DATABASE_USER     = "${aws_db_instance.delivery_db.username}"
    DATABASE_PASSWORD = "${aws_db_instance.delivery_db.password}"
    SERVER_PORT       = "3000"
    AUTH_PUT_CLIENT   = "https://fpgak1gq68.execute-api.us-east-1.amazonaws.com/Prod/"
  }
}
