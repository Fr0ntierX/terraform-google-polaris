provider "google" {
  alias = "impersonation"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_service_account_access_token" "default" {
  provider               = google.impersonation
  target_service_account = var.service_account
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "2400s"
}

provider "google" {
  project         = var.project_id
  region          = var.region
  access_token    = data.google_service_account_access_token.default.access_token
  request_timeout = "60s"
}