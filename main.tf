locals {
  region = substr(var.zone, 0, length(var.zone) - 2)

  network_interfaces = [for i, n in var.networks : {
    network     = n,
    subnetwork  = length(var.sub_networks) > i ? element(var.sub_networks, i) : null
    external_ip = length(var.external_ips) > i ? element(var.external_ips, i) : "NONE"
    }
  ]

  workload_env_map   = var.workload_env_vars != "" ? jsondecode(var.workload_env_vars) : {}
  workload_env_flags = join(" ", [for key, value in local.workload_env_map : "-e ${key}=\"${value}\""])

  token_service_definition = <<-EOT
    - path: /etc/systemd/system/tpm-token.service
      permissions: '0644'
      owner: root
      content: |
        [Unit]
        Description=Get TPM token
        Wants=gcr-online.target
        After=gcr-online.target

        [Service]
        Environment="HOME=/home/f0x"
        ExecStart=/var/lib/google/gotpm token --output /run/tpm_jwt_token
    - path: /etc/systemd/system/tpm-token.timer
      permissions: '0644'
      owner: root
      content: |
        [Unit]
        Description=Run TPM token service every 50 minutes

        [Timer]
        OnBootSec=1min
        OnUnitActiveSec=50min
        Unit=tpm-token.service

        [Install]
        WantedBy=timers.target
  EOT

  token_service_prep = <<-EOT
    - curl -L https://github.com/google/go-tpm-tools/releases/download/v0.4.4/go-tpm-tools_Linux_x86_64.tar.gz -o /var/lib/google/go-tpm-tools_Linux_x86_64.tar.gz
    - tar -xvf /var/lib/google/go-tpm-tools_Linux_x86_64.tar.gz -C /var/lib/google/
    - rm /var/lib/google/go-tpm-tools_Linux_x86_64.tar.gz
    - /var/lib/google/gotpm token --output /run/tpm_jwt_token
  EOT

  token_service_startup = <<-EOT
    - systemctl enable tpm-token.timer
    - systemctl start tpm-token.timer
  EOT

  polaris_proxy_docker_command = "/usr/bin/docker run -d --name polaris-proxy --network local-network -p ${var.polaris_proxy_port}:${var.polaris_proxy_port} -e POLARIS_CONTAINER_WORKLOAD_BASE_URL=http://client-workload:${var.workload_port} -e POLARIS_CONTAINER_KEY_TYPE=ephemeral ${var.polaris_proxy_enable_output_encryption ? "-e POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION=true" : ""} ${var.polaris_proxy_enable_input_encryption ? "-e POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION=true" : ""} ${var.polaris_proxy_enable_cors ? "-e POLARIS_CONTAINER_ENABLE_CORS=true" : ""} ${var.polaris_proxy_enable_logging ? "-e POLARIS_CONTAINER_ENABLE_LOGGING=true" : ""} ${var.polaris_proxy_image}:${var.polaris_proxy_image_version}"

  metadata = {
    user-data                = <<-EOT
    #cloud-config
    write_files:
    ${var.enable_kms ? local.token_service_definition : ""}
    - path: /etc/systemd/system/polaris-proxy.service
      permissions: '0644'
      owner: root
      content: |
        [Unit]
        Description=Start Polaris secure proxy container
        Wants=gcr-online.target
        After=gcr-online.target

        [Service]
        Environment="HOME=/home/f0x"
        ExecStartPre=/usr/bin/docker-credential-gcr configure-docker --registries us-docker.pkg.dev
        ExecStart=${var.enable_kms ? local.polaris_pro_proxy_docker_command : local.polaris_proxy_docker_command}
    - path: /etc/systemd/system/client-workload.service
      permissions: '0644'
      owner: root
      content: |
        [Unit]
        Description=Start client workload container
        Wants=gcr-online.target
        After=gcr-online.target

        [Service]
        Environment="HOME=/home/f0x"
        ExecStartPre=/usr/bin/docker-credential-gcr configure-docker --registries us-docker.pkg.dev
        ExecStart=/usr/bin/docker run -d --name client-workload --network local-network -p ${var.workload_port}:${var.workload_port} ${local.workload_env_flags != "" ? local.workload_env_flags : ""} ${var.workload_entrypoint != "" ? "--entrypoint ${var.workload_entrypoint}" : ""} ${var.workload_image} ${join(" ", var.workload_arguments)}

    runcmd:
    - |
      if ! /usr/bin/docker network ls | grep -q "local-network"; then
        /usr/bin/docker network create local-network
      fi
    ${var.enable_kms ? local.token_service_prep : ""}
    - systemctl daemon-reload
    ${var.enable_kms ? local.token_service_startup : ""}
    - systemctl start polaris-proxy.service
    - systemctl start client-workload.service
  EOT
    google-logging-enable    = "0"
    google-monitoring-enable = "0"
  }
}

resource "google_project_service" "cloudkms" {
  count   = var.enable_kms ? 1 : 0
  project = var.project_id
  service = "cloudkms.googleapis.com"
}

resource "google_project_service" "confidentialcomputing" {
  project = var.project_id
  service = "confidentialcomputing.googleapis.com"
}

resource "google_compute_instance" "instance" {
  depends_on = [google_project_service.confidentialcomputing]

  name             = "${var.goog_cm_deployment_name}-vm"
  machine_type     = var.machine_type
  zone             = var.zone
  min_cpu_platform = "AMD Milan"

  tags = ["${var.goog_cm_deployment_name}-deployment"]

  confidential_instance_config {
    enable_confidential_compute = true
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  boot_disk {
    device_name = "${var.goog_cm_deployment_name}-boot-disk"

    initialize_params {
      size  = var.boot_disk_size
      type  = var.boot_disk_type
      image = var.source_image
    }
  }

  metadata = local.metadata

  dynamic "network_interface" {
    for_each = local.network_interfaces
    content {
      network    = network_interface.value.network
      subnetwork = network_interface.value.subnetwork

      dynamic "access_config" {
        for_each = network_interface.value.external_ip == "NONE" ? [] : [1]
        content {
          nat_ip = network_interface.value.external_ip == "EPHEMERAL" ? null : network_interface.value.external_ip
        }
      }
    }
  }

  service_account {
    email = var.service_account
    scopes = compact([
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ])
  }
}

resource "google_compute_firewall" "secure_container_tcp" {
  count = var.polaris_proxy_source_ranges == "" ? 0 : 1

  name    = "${var.goog_cm_deployment_name}-secure-container-tcp"
  network = element(var.networks, 0)

  allow {
    ports    = [var.polaris_proxy_port]
    protocol = "tcp"
  }

  source_ranges = compact([for range in split(",", var.polaris_proxy_source_ranges) : trimspace(range)])

  target_tags = ["${var.goog_cm_deployment_name}-deployment"]
}
