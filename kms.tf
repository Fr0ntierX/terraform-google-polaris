locals {
  name_prefix                          = substr(var.name, 0, 23)
  federated_credentials_audience        = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.wip-attestation-verifier.name}"
  federated_credentials_service_account = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${google_service_account.key_account.email}:generateAccessToken"
  polaris_proxy_image                  = "fr0ntierx/polaris-proxy"

  polaris_pro_proxy_docker_command = "/usr/bin/docker run -d --name polaris-proxy --network local-network -p 3000:3000 -v /run/tpm_jwt_token:/run/container_launcher/attestation_verifier_claims_token -e POLARIS_CONTAINER_WORKLOAD_BASE_URL=http://client-workload:8000 -e POLARIS_CONTAINER_KEY_TYPE=google-federated ${var.polaris_proxy_enable_output_encryption ? "-e POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION=true" : ""} ${var.polaris_proxy_enable_input_encryption ? "-e POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION=true" : ""} ${var.polaris_proxy_enable_cors ? "-e POLARIS_CONTAINER_ENABLE_CORS=true" : ""} ${var.polaris_proxy_enable_logging ? "-e POLARIS_CONTAINER_ENABLE_LOGGING=true" : ""} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY_PROJECT_ID=${var.project_id} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY_LOCATION=${local.region} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY_RING_ID=${google_kms_key_ring.default.name} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY_ID=${google_kms_crypto_key.default.name} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY_AUDIENCE=${local.federated_credentials_audience} -e POLARIS_CONTAINER_GOOGLE_FEDERATED_KEY__SERVICE_ACCOUNT=${local.federated_credentials_service_account} ${local.polaris_proxy_image}:${var.polaris_proxy_image_version}"
}

resource "google_service_account" "key_account" {
  account_id = "${local.name_prefix}-key-sa"
}


resource "google_kms_key_ring" "default" {
  name     = "${local.name_prefix}-keyring"
  location = local.region
}

resource "google_kms_crypto_key" "default" {
  name     = "${local.name_prefix}-key"
  key_ring = google_kms_key_ring.default.id
  purpose  = "ASYMMETRIC_DECRYPT"

  version_template {
    algorithm        = "RSA_DECRYPT_OAEP_4096_SHA256"
    protection_level = "HSM"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_iam_workload_identity_pool" "wip" {
  workload_identity_pool_id = "${local.name_prefix}-wip"
  description               = "Workload Identity Pool for access to the key service account's resources"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "wip-attestation-verifier" {
  workload_identity_pool_provider_id = "${local.name_prefix}-provider"
  workload_identity_pool_id          = google_iam_workload_identity_pool.wip.workload_identity_pool_id

  attribute_mapping = {
    "google.subject" = "'assertion.sub'"
  }

  oidc {
    issuer_uri        = "https://confidentialcomputing.googleapis.com/"
    allowed_audiences = ["https://sts.googleapis.com"]
  }
}

resource "google_service_account_iam_binding" "key-wip-binding" {
  service_account_id = google_service_account.key_account.id
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.wip.name}/*"]
}

resource "google_kms_crypto_key_iam_binding" "key_service_account_binding" {
  for_each = toset([
    "roles/cloudkms.cryptoKeyDecrypter",
    "roles/cloudkms.cryptoKeyEncrypter",
    "roles/cloudkms.publicKeyViewer",
    "roles/cloudkms.viewer",
  ])

  crypto_key_id = google_kms_crypto_key.default.id
  role          = each.value

  members = ["serviceAccount:${google_service_account.key_account.email}"]
}
