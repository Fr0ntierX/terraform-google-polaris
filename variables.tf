variable "project_id" {
  type        = string
  description = "Name ot the GCP project"
}

variable "region" {
  type        = string
  description = "Name of GCP region used by the project"
}

variable "terraform_service_account" {
  description = "terraform service account"
  type        = string
}

variable "test" {
  type        = string
  description = "Test Variable"
}
