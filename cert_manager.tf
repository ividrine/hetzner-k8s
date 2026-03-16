data "helm_template" "cert_manager" {
  name         = "cert-manager"
  namespace    = "cert-manager"
  chart        = "cert-manager"
  repository   = "https://charts.jetstack.io"
  version      = var.cert_manager_version
  kube_version = var.kubernetes_version

  values = [
    yamlencode({
      crds            = { enabled = true }
      startupapicheck = { enabled = false }
      nodeSelector    = { "node-role.kubernetes.io/control-plane" : "" }
      tolerations = [
        {
          key      = "node-role.kubernetes.io/control-plane"
          effect   = "NoSchedule"
          operator = "Exists"
        }
      ]
      webhook = {
        nodeSelector = { "node-role.kubernetes.io/control-plane" : "" }
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            effect   = "NoSchedule"
            operator = "Exists"
          }
        ]
      }
      cainjector = {
        nodeSelector = { "node-role.kubernetes.io/control-plane" : "" }
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            effect   = "NoSchedule"
            operator = "Exists"
          }
        ]
      }
    })
  ]
}

locals {

  cert_manager_namespace = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "cert-manager"
    }
  })

  cert_manager_manifest = {
    name     = "cert-manager"
    contents = <<-EOF
      ${local.cert_manager_namespace}
      ---
      ${data.helm_template.cert_manager.manifest}
    EOF
  }
}
