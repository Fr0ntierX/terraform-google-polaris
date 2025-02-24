variable "project_id" {
  type        = string
}

variable "goog_cm_deployment_name" {
  type        = string
}

variable "region" {
  type        = string
}

variable "zone" {
  type        = string
}

variable "machine_type" {
  type        = string
}

variable "source_image" {
  type        = string
}

variable "service_account" {
  type        = string
}

variable "workload_image" {
  type        = string
}

variable "workload_port" {
  type        = string
}

variable "workload_env_vars" {
  type        = string
}

variable "polaris_proxy_image" {
  type        = string
}

variable "polaris_proxy_port" {
  type        = string
}

variable "networks" {
  type        = list(string)
}

variable "sub_networks" {
  type        = list(string)
}

variable "external_ips" {
  type        = list(string)
}

variable "enable_kms" {
  type        = bool
}