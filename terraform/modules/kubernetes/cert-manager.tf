resource "helm_release" "cert_manager" {
  name              = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  namespace         = "cert-manager"
  create_namespace  = true
  version           = "v1.8.0"
  dependency_update = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
