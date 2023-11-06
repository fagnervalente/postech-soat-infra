resource "kubernetes_manifest" "manifests" {
  for_each = fileset("infra/", "*.yaml")
  manifest = yamldecode(file("test/${each.value}"))
}