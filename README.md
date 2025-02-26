# Polaris Terraform Module

## Overview
The Polaris Terraform Module provisions a secure VM in Google Cloud with Confidential Computing enabled. It deploys two Docker containers:
- **Polaris Proxy:** Exposes a secure service with configurable encryption, CORS, and logging.
- **Client Workload:** Runs your custom workload.

Optional integration with Cloud KMS enables enhanced security through asymmetric decryption backed by HSM, alongside workload identity federation.

## Requirements

| Requirement                          | Details                                                                        |
|--------------------------------------|--------------------------------------------------------------------------------|
| Terraform                            | >= 1.9.8                                                                       |
| Google Provider                      | >= 6.10.0                                                                      |
| GCP Project                          | Billing enabled with necessary IAM permissions                                 |

## Key Differences Between Polaris and Polaris Pro
- **Polaris:** Standard secure VM with Docker containers.
- **Polaris Pro:** In addition to the standard setup, it enables Cloud KMS integration, providing enhanced security via HSM-backed asymmetric decryption and workload identity federation, which may incur additional costs.

## Pricing Considerations
Be aware that deploying Polaris Pro (with `enable_kms = true`) may incur additional costs compared to the standard Polaris deployment. The Polaris Pro mode leverages Cloud KMS and workload identity federation, which have their own pricing. Please refer to the relevant GCP pricing documentation for Cloud KMS, identity federation, and confidential computing features for detailed cost estimates.

## Variables
| Name                            | Type               | Description                                                               | Default                                  |
|---------------------------------|--------------------|---------------------------------------------------------------------------|------------------------------------------|
| project_id                      | string             | GCP Project ID for provisioning resources.                                | N/A                                      |
| deployment_name                 | string             | Name of the deployment and VM instance.                                   | N/A                                      |
| source_image                    | string             | Disk image used for creating the VM.                                      | projects/fr0ntierx-public/global/images/polaris-dev-image |
| enable_kms                      | bool               | Enable Cloud KMS integration for Polaris Proxy.                           | false                                    |
| region                          | string             | Region for resource deployment.                                           | N/A                                      |
| zone                            | string             | Zone where the instance will be deployed.                                 | us-central1-a                            |
| machine_type                    | string             | VM machine type.                                                          | n2d-standard-2                           |
| boot_disk_type                  | string             | Type of boot disk for the VM.                                             | pd-ssd                                   |
| boot_disk_size                  | number             | Boot disk size in GB.                                                     | 10                                       |
| networks                        | list(string)       | Networks where the VM will be created.                                    | ["default"]                              |
| sub_networks                    | list(string)       | Subnets for VM deployment.                                                | ["default"]                              |
| external_ips                    | list(string)       | External IP configuration for the VM.                                     | ["EPHEMERAL"]                            |
| service_account                 | string             | Service Account used by the Compute Instance.                             | ""                                       |                                    |
| polaris_proxy_port              | string             | Port exposed by the Polaris Proxy.                                        | "3000"                                   |
| polaris_proxy_source_ranges     | string             | Comma-separated list of source IP ranges allowed to access the proxy.       | ""                                       |
| polaris_proxy_enable_input_encryption  | bool       | Enable input encryption on the proxy container.                           | false                                    |
| polaris_proxy_enable_output_encryption | bool       | Enable output encryption on the proxy container.                          | false                                    |
| polaris_proxy_enable_cors       | bool               | Enable CORS support for Polaris Proxy.                                    | false                                    |
| polaris_proxy_enable_logging    | bool               | Enable logging in the Polaris Proxy.                                      | true                                     |
| polaris_proxy_image             | string             | Docker image URL for the Polaris Proxy.                                   | N/A                                      |
| polaris_proxy_image_version     | string             | Image version tag of the Polaris Proxy.                                   | "latest"                                 |
| workload_port                   | string             | Port on which the workload container runs.                                | "8000"                                   |
| workload_image                  | string             | Docker image URL for the client workload container.                       | N/A                                      |
| workload_entrypoint             | string             | Entrypoint command for the workload container.                            | ""                                       |
| workload_arguments              | list(string)       | Arguments to pass to the workload container.                              | []                                       |
| workload_env_vars               | string             | JSON-formatted environment variables for the workload container.          | ""                                       |

## Module Modes
The module offers two modes depending on the value of `enable_kms`:

| Feature                          | Polaris (enable_kms = false)                         | Polaris Pro (enable_kms = true)                      |
|----------------------------------|------------------------------------------------------|------------------------------------------------------|
| VM Deployment                    | Standard secure VM with Docker containers            | Secure VM with additional KMS and workload identity support |
| Container                        | Polaris Proxy                                        | Polaris Proxy configured for secure key management   |
| KMS Integration                  | Not enabled                                          | Cloud KMS key ring and crypto key are provisioned     |
| Identity Federation              | N/A                                                  | Workload Identity Pool and Provider configuration     |

## Outputs
| Output Name            | Description                                    |
|------------------------|------------------------------------------------|
| instance_self_link     | Self-link URL for the Compute Instance.        |
| instance_zone          | Zone where the instance is deployed.           |
| instance_machine_type  | Type of the deployed Compute Instance.         |
| instance_nat_ip        | External IP assigned to the instance.          |
| instance_network       | Primary network associated with the instance.  |

## Architecture
The module provisions the following resources:
- **Compute Instance:** A secure VM with Confidential Computing (AMD SEV and shielded instance configurations).
- **Docker Containers:** Bootstrapped via cloud-init metadata:
  - **Polaris Proxy Container:** Securely exposed with configurable networking and encryption settings.
  - **Client Workload Container:** Runs your application code.
- **Firewall Rules:** Restrict access to the proxy based on allowed source ranges.
- **Optional Cloud KMS Setup:** When enabled, creates a Key Ring, Crypto Key (HSM-backed), and configures Workload Identity Federation for secure key management.

## Detailed Configuration & Examples

### Confidential Computing
- **Shielded Instance Config:** Secure boot, virtual TPM, and integrity monitoring are enabled.
- **Confidential Instance Config:** Utilizes AMD SEV for memory encryption.

### Docker & Metadata Setup
- **Cloud-Init Script:** Configures the local Docker network, pulls images, and starts the Polaris Proxy and Workload containers.
- **TPM Token Setup:** When KMS is active, additional steps are executed to obtain TPM tokens for attestation.

### KMS and Workload Identity (Optional)
When `enable_kms` is true:
- Provisions Cloud KMS Key Ring and Crypto Key with `ASYMMETRIC_DECRYPT` purpose.
- Creates a Workload Identity Pool and Provider to allow federated identities secure access.

### Usage Example
Below is a sample configuration:
```hcl
module "polaris" {
  source                    = "./polaris-terraform-module"
  project_id                = "my-project"
  deployment_name           = "polaris-instance"
  region                    = "us-central1"
  zone                      = "us-central1-a"
  machine_type              = "n2d-standard-2"
  service_account           = "my-service-account@my-project.iam.gserviceaccount.com"
  polaris_proxy_image       = "us-docker.pkg.dev/my-registry/polaris-proxy"
  workload_image            = "us-docker.pkg.dev/my-registry/client-workload"
  enable_kms                = true  # Switches between Polaris (false) and Polaris Pro (true)
  // ...additional configuration...
}
```

### Deployment Steps
1. Initialize Terraform:
   ```sh
   terraform init
   ```
2. Plan the deployment:
   ```sh
   terraform plan
   ```
3. Apply the configuration:
   ```sh
   terraform apply
   ```

### Examples Comparison Table

| Feature                         | Enabled Example                     | Description                                                           |
|---------------------------------|-------------------------------------|-----------------------------------------------------------------------|
| Standard VM Deployment          | enable_kms = false                  | Deploys a VM with Docker containers only.                           |
| Secure VM with KMS              | enable_kms = true                   | Deploys a VM with additional Cloud KMS and identity federation.      |
| Custom Boot Disk                | boot_disk_size = 50                 | Deploys a VM with a 50GB boot disk instead of the default 10GB.         |

## Further Documentation
For additional customizations and advanced usage, refer to:
- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud KMS Documentation](https://cloud.google.com/kms/docs)
- [Terraform Cloud-Init Examples](https://www.terraform.io/docs/language/meta-arguments/metadata.html)