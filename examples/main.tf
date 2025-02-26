provider "google" {
  project = var.project_id
  region  = var.region
}

module "polaris" {
  source = "../"

  project_id                = var.project_id
  deployment_name           = var.deployment_name
  region                    = var.region
  workload_image            = var.workload_image
  service_account           = var.service_account
  zone                      = var.zone
  polaris_proxy_port        = var.polaris_proxy_port
  networks                  = var.networks
  sub_networks              = var.sub_networks
  external_ips              = var.external_ips
  polaris_proxy_image       = var.polaris_proxy_image
  workload_port             = var.workload_port
  workload_env_vars         = var.workload_env_vars
}