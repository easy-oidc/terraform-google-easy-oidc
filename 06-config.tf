# Easy OIDC <https://easy-oidc.dev>
# Copyright The Easy OIDC Authors
# SPDX-License-Identifier: Apache-2.0

locals {
  config_jsonc = jsonencode({
    issuer_url       = local.issuer_url
    http_listen_addr = "127.0.0.1:8080"
    data_dir         = "/var/lib/easy-oidc"

    secrets = {
      provider              = "gcp"
      signing_key_name      = var.signing_key_secret_name
      connector_secret_name = var.connector_secret_name
    }

    connector = merge(
      {
        type = var.connector_type
      },
      var.connector_type == "google" && var.connector_hosted_domain != null ? {
        google = {
          hd = var.connector_hosted_domain
        }
      } : {},
      var.connector_type == "github" ? {
        github = {
          hostname = var.connector_github_hostname
        }
      } : {}
    )

    default_redirect_uris = var.default_redirect_uris
    groups_overrides      = var.groups_overrides
    clients = { for client_id, config in var.clients : client_id => {
      redirect_uris   = config.redirect_uris != null ? config.redirect_uris : null
      groups_override = config.groups_override != null ? config.groups_override : null
    } if config.redirect_uris != null || config.groups_override != null }
  })
}
