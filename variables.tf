# Easy OIDC <https://easy-oidc.dev>
# Copyright The Easy OIDC Authors
# SPDX-License-Identifier: Apache-2.0

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "easy-oidc"
}

variable "labels" {
  description = "Additional labels to apply to supported resources"
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "GCP project ID. If null, uses the project from the Google provider configuration."
  type        = string
  default     = null
}

variable "region" {
  description = "GCP region for regional resources. If null, uses the region from the Google provider configuration."
  type        = string
  default     = null
}

variable "zone" {
  description = "GCP zone for the Compute Engine instance. If null, uses the zone from the Google provider configuration."
  type        = string
  default     = null
}

variable "network" {
  description = "VPC network name, self-link, or ID where easy-oidc will be deployed"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name, self-link, or ID for the instance. If null, a public subnetwork is created."
  type        = string
  default     = null
}

variable "subnetwork_cidr" {
  description = "IPv4 CIDR range for the auto-created subnetwork"
  type        = string
  default     = "10.0.0.0/24"
}

variable "oidc_addr" {
  description = "OIDC server address (e.g., 'auth.example.com' or 'auth.example.com:8443')"
  type        = string
}

variable "connector_type" {
  description = "Upstream connector type: 'google' or 'github'"
  type        = string
  validation {
    condition     = contains(["google", "github"], var.connector_type)
    error_message = "connector_type must be 'google' or 'github'"
  }
}

variable "connector_secret_name" {
  description = "GCP Secret Manager secret version name containing OAuth client credentials JSON (projects/*/secrets/*/versions/*)"
  type        = string
}

variable "signing_key_secret_name" {
  description = "GCP Secret Manager secret version name containing Ed25519 signing key PEM (projects/*/secrets/*/versions/*)"
  type        = string
  default     = null
}

variable "default_redirect_uris" {
  description = "Default redirect URIs for OIDC clients"
  type        = list(string)
  default     = ["http://localhost:8000"]
}

variable "groups_overrides" {
  description = "Map of group override keys to email-to-groups mappings"
  type        = map(map(list(string)))
  default     = {}
}

variable "clients" {
  description = "Map of OIDC client configurations (key is client_id)"
  type = map(object({
    redirect_uris   = optional(list(string))
    groups_override = optional(string)
  }))
}

variable "enable_ipv4" {
  description = "Enable IPv4 public address support"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 public address support. The selected or created subnetwork must support external IPv6."
  type        = bool
  default     = true
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "boot_disk_kms_key_self_link" {
  description = "Cloud KMS key self-link for boot disk encryption. If null, Google-managed encryption is used."
  type        = string
  default     = null
}

variable "allowed_cidrs_ipv4" {
  description = "Allowed IPv4 CIDRs for HTTP/HTTPS access (ignored if enable_ipv4 = false)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_cidrs_ipv6" {
  description = "Allowed IPv6 CIDRs for HTTP/HTTPS access (ignored if enable_ipv6 = false)"
  type        = list(string)
  default     = ["::/0"]
}

variable "connector_hosted_domain" {
  description = "Google hosted domain (hd parameter) - only used with connector_type=google"
  type        = string
  default     = null
}

variable "connector_github_hostname" {
  description = "GitHub hostname for GitHub Enterprise - only used with connector_type=github"
  type        = string
  default     = "github.com"
}

variable "easy_oidc_version" {
  description = "Version of easy-oidc to install (git tag or 'latest')"
  type        = string
  default     = "latest"
}

variable "caddy_version" {
  description = "Version of Caddy to install (or 'latest' to use script default)"
  type        = string
  default     = "latest"
}

variable "service_account_email" {
  description = "Existing service account email to attach to the instance. If null, one is created."
  type        = string
  default     = null
}

variable "grant_secret_accessor" {
  description = "Grant roles/secretmanager.secretAccessor on the project to the instance service account. Disable if permissions are managed externally."
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "Optional SSH public keys for instance metadata, in GCE metadata format (username:ssh-rsa ...). Leave empty to disable SSH in userdata."
  type        = list(string)
  default     = []
}
