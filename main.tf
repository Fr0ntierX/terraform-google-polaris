
resource "google_storage_bucket" "bucket" {
  name     = var.test
  location = "US"
}
