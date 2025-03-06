module "polaris-terraform-module" {
  source = "Fr0ntierX/polaris/google"

  # Project Configuration
  project_id      = "polaris-terraform"
  name            = "anonymization-service"
  region          = "us-central1"
  zone            = "us-central1-a"

  # Service Configuration
  service_account = "terraform-automation@polaris-terraform.iam.gserviceaccount.com"
  workload_image  = "fr0ntierx/anonymization-service"
  workload_port   = "8000"

  # Network Configuration
  networks     = ["default"]
  sub_networks = ["default"]
  external_ips = ["EPHEMERAL"]

  # Polaris Proxy Configuration
  polaris_proxy_port  = "3000"

  enable_kms = true
}
