# Easy OIDC <https://easy-oidc.dev>
# Copyright The Easy OIDC Authors
# SPDX-License-Identifier: Apache-2.0

output "issuer_url" {
  description = "OIDC issuer URL"
  value       = local.issuer_url
}

output "client_ids" {
  description = "List of configured OIDC client IDs"
  value       = keys(var.clients)
}

output "enable_ipv4" {
  description = "Whether IPv4 is enabled"
  value       = var.enable_ipv4
}

output "enable_ipv6" {
  description = "Whether IPv6 is enabled"
  value       = var.enable_ipv6
}

output "public_ipv4" {
  description = "Public IPv4 address (null if IPv4 disabled)"
  value       = var.enable_ipv4 ? google_compute_address.ipv4[0].address : null
}

output "public_ipv6" {
  description = "Public IPv6 address (null if IPv6 disabled)"
  value       = var.enable_ipv6 ? google_compute_address.ipv6[0].address : null
}

output "instance_id" {
  description = "Compute Engine instance ID"
  value       = google_compute_instance.main.instance_id
}

output "instance_name" {
  description = "Compute Engine instance name"
  value       = google_compute_instance.main.name
}

output "subnetwork" {
  description = "Subnetwork used by the instance"
  value       = local.subnetwork
}

output "service_account_email" {
  description = "Service account attached to the instance"
  value       = local.service_account_email
}

output "instance_arch" {
  description = "Detected instance architecture (arm64 or amd64)"
  value       = local.instance_arch
}

output "easy_oidc_version" {
  description = "Resolved easy-oidc version (pinned from 'latest' if applicable)"
  value       = local.easy_oidc_version_resolved
}

output "caddy_version" {
  description = "Resolved Caddy version (pinned from 'latest' if applicable)"
  value       = local.caddy_version_resolved
}
