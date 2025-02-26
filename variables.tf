variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "deployment_name" {
  description = "The name of the deployment and VM instance."
  type        = string
}

variable "source_image" {
  description = "The disk image to create the VM instance from."
  type        = string
  default     = "projects/fr0ntierx-public/global/images/polaris-dev-image"
}

variable "enable_kms" {
  description = "Whether to enable KMS key for the Polaris container (Polaris Pro)"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region to deploy resources to."
  type        = string
}

// Machine definition
variable "zone" {
  description = "The zone where the VM will be deployed."
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "The machine type of the VM."
  type        = string
  default     = "n2d-standard-2"
}

variable "boot_disk_type" {
  description = "The boot disk type for the VM instance."
  type        = string
  default     = "pd-ssd"
}

variable "boot_disk_size" {
  description = "The boot disk size for the VM instance in GBs"
  type        = number
  default     = 10
}

variable "networks" {
  description = "The networks where the VM will be created"
  type        = list(string)
  default     = ["default"]
}

variable "sub_networks" {
  description = "The subnets where the VM will be created"
  type        = list(string)
  default     = ["default"]
}

variable "external_ips" {
  description = "The external IPs assigned to the VM."
  type        = list(string)
  default     = ["EPHEMERAL"]
}

variable "service_account" {
  description = "Service Account that will run the VM"
  type        = string
  default     = ""
}

// Polaris Proxy Configuration
variable "polaris_proxy_port" {
  description = "Port that will be exposed by the Polaris Container"
  type        = string
  default     = "3000"
}

variable "polaris_proxy_source_ranges" {
  description = "Source IP ranges to allow for incoming traffic to the container"
  type        = string
  default     = ""
}

variable "polaris_proxy_enable_input_encryption" {
  description = "Enable input encryption"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_output_encryption" {
  description = "Enable output encryption"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_cors" {
  description = "Enable CORS"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_logging" {
  description = "Enable logging"
  type        = bool
  default     = true
}

variable "polaris_proxy_image" {
  description = "Docker image URL of the Polaris Proxy"
  type        = string
}

variable "polaris_proxy_image_version" {
  description = "Customer Container Image Version"
  type        = string
  default     = "latest"
}

// Client Workload Configuration
variable "workload_port" {
  description = "Port that the workload will be run on"
  type        = string
  default     = "8000"
}

variable "workload_image" {
  description = "Docker image URL of the client workload"
  type        = string
}

variable "workload_entrypoint" {
  description = "Entrypoint of the workload container"
  type        = string
  default     = ""
}

variable "workload_arguments" {
  description = "Arguments of the workload container"
  type        = list(string)
  default     = []
}

variable "workload_env_vars" {
  description = "Environment variables to be passed to the workload container"
  type        = string
  default     = ""
}
