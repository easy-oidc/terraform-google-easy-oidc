# Easy OIDC <https://easy-oidc.dev>
# Copyright The Easy OIDC Authors
# SPDX-License-Identifier: Apache-2.0

resource "google_compute_instance" "main" {
  project      = local.project_id
  name         = var.name_prefix
  zone         = local.zone
  machine_type = var.machine_type

  tags   = [local.network_tag]
  labels = local.labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
    kms_key_self_link = var.boot_disk_kms_key_self_link
  }

  network_interface {
    subnetwork = local.subnetwork

    dynamic "access_config" {
      for_each = var.enable_ipv4 ? [1] : []
      content {
        nat_ip       = google_compute_address.ipv4[0].address
        network_tier = "PREMIUM"
      }
    }

    dynamic "ipv6_access_config" {
      for_each = var.enable_ipv6 ? [1] : []
      content {
        external_ipv6               = google_compute_address.ipv6[0].address
        external_ipv6_prefix_length = 96
        network_tier                = "PREMIUM"
      }
    }
  }

  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = merge(
    {
      enable-oslogin = "FALSE"
    },
    length(var.ssh_keys) > 0 ? {
      ssh-keys = join("\n", var.ssh_keys)
    } : {}
  )

  metadata_startup_script = local.userdata

  allow_stopping_for_update = true

  lifecycle {
    precondition {
      condition     = var.enable_ipv4 || var.enable_ipv6
      error_message = "At least one of enable_ipv4 or enable_ipv6 must be true so the instance can download dependencies and serve OIDC traffic."
    }

    replace_triggered_by = [
      google_compute_address.ipv4,
      google_compute_address.ipv6,
    ]
  }
}
