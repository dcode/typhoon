# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/dcode/terraform-render-bootstrap.git?ref=cb695b2a5cb7b22a427be85aa0b41866bb5cad88"

  cluster_name           = var.cluster_name
  api_servers            = [var.k8s_domain_name]
  service_account_issuer = var.service_account_issuer
  etcd_servers           = var.controllers.*.domain
  networking             = var.networking
  pod_cidr               = var.pod_cidr
  service_cidr           = var.service_cidr
  components             = var.components

  k8s_ca_cert            = var.k8s_ca_cert
  k8s_ca_key             = var.k8s_ca_key
  etcd_ca_cert           = var.etcd_ca_cert
  etcd_ca_key            = var.etcd_ca_key
  aggregation_ca_cert    = var.aggregation_ca_cert
  aggregation_ca_key     = var.aggregation_ca_key
}


