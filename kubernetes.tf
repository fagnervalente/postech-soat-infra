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
    RUN_ON: "production"
    SERVER_PORT       = "3000"
    AUTH_PUT_CLIENT   = "https://fpgak1gq68.execute-api.us-east-1.amazonaws.com/Prod/"
    MERCADOPAGO_ACCESS_TOKEN: ""
    DATABASE_HOST     = "${aws_db_instance.delivery_db.address}"
    DATABASE_NAME     = "${aws_db_instance.delivery_db.db_name}"
    DATABASE_PORT     = "${aws_db_instance.delivery_db.port}"
    DATABASE_USER     = "${aws_db_instance.delivery_db.username}"
    DATABASE_PASSWORD = "${aws_db_instance.delivery_db.password}"
    DATABASE_MONGO_HOST = "${aws_docdb_cluster.docdb.endpoint}"
    DATABASE_MONGO_PORT = "${aws_docdb_cluster.docdb.port}"
    DATABASE_MONGO_USER = "${aws_docdb_cluster.docdb.master_username}"
    DATABASE_MONGO_PASSWORD = "${aws_docdb_cluster.docdb.master_password}"
    DATABASE_MONGO_NAME = "${aws_docdb_cluster.docdb.engine}"
    ORDER_SERVICE_ENDPOINT = "http://svc-microservice-order:3010/order"
    PROCESS_SERVICE_ENDPOINT = "http://svc-microservice-process:3000"
    PAYMENT_SERVICE_ENDPOINT = "http://svc-microservice-payment:3000"
    PRODUCT_SERVICE_ENDPOINT = "http://svc-microservice-produt:3000"
    USER_SERVICE_ENDPOINT = "http://svc-microservice-user:3000"
  }
}
