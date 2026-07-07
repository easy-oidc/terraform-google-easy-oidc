<!--
Easy OIDC <https://easy-oidc.dev>
Copyright The Easy OIDC Authors
SPDX-License-Identifier: Apache-2.0
-->

# terraform-google-easy-oidc

Terraform module for deploying [easy-oidc](https://github.com/easy-oidc/easy-oidc) on Google Cloud Platform (GCP).

Provisions a minimal OIDC server designed for use with Kubernetes, with Google/GitHub federation and support for static group overrides.

## Features

- **Single Compute Engine instance** deployment (`e2-micro` by default)
- **Dual-stack IPv4/IPv6** support when the selected subnetwork supports external IPv6
- **Auto-subnetwork creation** if no subnetwork is specified
- **Caddy reverse proxy** with automatic Let's Encrypt TLS (requires DNS to be configured on hostname)
- **GCP Secret Manager** for signing keys and OAuth credentials
- **Static group mappings** for Kubernetes RBAC

## Prerequisites

### Enable required GCP APIs

Enable the required Google Cloud APIs in the target project before applying the module:

```bash
gcloud services enable \
  compute.googleapis.com \
  iam.googleapis.com \
  secretmanager.googleapis.com \
  cloudresourcemanager.googleapis.com
```

If you use the Cloud DNS example below, also enable the Cloud DNS API:

```bash
gcloud services enable dns.googleapis.com
```

Create secrets in GCP Secret Manager before deploying:

### 1. OAuth Client Credentials

**For Google:**
```bash
gcloud secrets create easy-oidc-connector-secret \
  --replication-policy=automatic \
  --data-file=<(cat <<'JSON'
{
  "client_id": "123456789.apps.googleusercontent.com",
  "client_secret": "GOCSPX-xxxxxxxxxxxxxxxxxxxxx"
}
JSON
)
```

**For GitHub:**
```bash
gcloud secrets create easy-oidc-connector-secret \
  --replication-policy=automatic \
  --data-file=<(cat <<'JSON'
{
  "client_id": "Iv1.abc123def456",
  "client_secret": "abc123def456..."
}
JSON
)
```

### 2. Signing Key (Ed25519)

```bash
openssl genpkey -algorithm ed25519 | \
  gcloud secrets create easy-oidc-signing-key \
    --replication-policy=automatic \
    --data-file=-
```

Pass secret **version names** to this module, for example:

```hcl
connector_secret_name   = "projects/my-project/secrets/easy-oidc-connector-secret/versions/latest"
signing_key_secret_name = "projects/my-project/secrets/easy-oidc-signing-key/versions/latest"
```

## Usage

```hcl
provider "google" {
  project = "my-project"
  region  = "us-central1"
  zone    = "us-central1-a"
}

locals {
  oidc_hostname = "auth.example.com"
}

resource "google_compute_network" "main" {
  name                    = "easy-oidc"
  auto_create_subnetworks = false
}

module "easy_oidc" {
  source = "easy-oidc/easy-oidc/google"

  network                 = google_compute_network.main.self_link
  oidc_addr               = local.oidc_hostname
  connector_type          = "google"
  connector_secret_name   = "projects/my-project/secrets/easy-oidc-connector-secret/versions/latest"
  signing_key_secret_name = "projects/my-project/secrets/easy-oidc-signing-key/versions/latest"

  default_redirect_uris = ["http://localhost:8000"]
  groups_overrides = {
    prod-groups = {
      "alice@example.com" = ["prod-admins", "devs"]
      "bob@example.com"   = ["prod-readonly"]
    }
  }
  clients = {
    kubelogin-prod = {
      groups_override = "prod-groups"
    }
    kubelogin-dev = {
      # Uses default_redirect_uris and upstream IdP groups
    }
  }
}

# Configure DNS records in your DNS provider.
# If using Cloud DNS:
data "google_dns_managed_zone" "main" {
  name = "example-com"
}

resource "google_dns_record_set" "oidc_a" {
  count = module.easy_oidc.public_ipv4 != null ? 1 : 0

  managed_zone = data.google_dns_managed_zone.main.name
  name         = "${local.oidc_hostname}."
  type         = "A"
  ttl          = 300
  rrdatas      = [module.easy_oidc.public_ipv4]
}

resource "google_dns_record_set" "oidc_aaaa" {
  count = module.easy_oidc.public_ipv6 != null ? 1 : 0

  managed_zone = data.google_dns_managed_zone.main.name
  name         = "${local.oidc_hostname}."
  type         = "AAAA"
  ttl          = 300
  rrdatas      = [module.easy_oidc.public_ipv6]
}
```

## Existing Subnetwork

```hcl
module "easy_oidc" {
  source = "easy-oidc/easy-oidc/google"

  network    = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.public.self_link

  # ... other variables ...
}
```

If `enable_ipv6 = true`, the existing subnetwork must support external IPv6.

## Kubernetes Integration

### API Server Flags

```bash
--oidc-issuer-url=https://auth.example.com
--oidc-client-id=kubelogin-prod
--oidc-username-claim=email
--oidc-groups-claim=groups
```

### kubeconfig Example

You can auth kubectl using [kubelogin](https://github.com/int128/kubelogin).

Example kubeconfig:

```yaml
users:
  - name: oidc-prod
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1
        command: kubelogin
        args:
          - get-token
          - --oidc-issuer-url=https://auth.example.com
          - --oidc-client-id=kubelogin-prod
          - --oidc-use-pkce
```

or test with:

```bash
kubectl oidc-login setup \
    --oidc-issuer-url=https://auth.example.com \
    --oidc-client-id=kubelogin-prod \
    --oidc-use-pkce
```

## IPv4-Only Deployment

```hcl
module "easy_oidc" {
  source = "easy-oidc/easy-oidc/google"

  network     = google_compute_network.main.self_link
  enable_ipv6 = false
  # ... other variables ...
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | `string` | `"easy-oidc"` | no |
| labels | Additional labels to apply to supported resources | `map(string)` | `{}` | no |
| project_id | GCP project ID | `string` | provider project | no |
| region | GCP region | `string` | provider region | no |
| zone | GCP zone | `string` | provider zone | no |
| network | VPC network name/self-link/ID | `string` | - | yes |
| oidc_addr | OIDC server address | `string` | - | yes |
| connector_type | Upstream IdP: `google` or `github` | `string` | - | yes |
| connector_secret_name | Secret Manager version name for OAuth credentials | `string` | - | yes |
| clients | Map of OIDC client configurations | `map(object)` | - | yes |
| subnetwork | Subnetwork name/self-link/ID (auto-created if omitted) | `string` | `null` | no |
| subnetwork_cidr | IPv4 CIDR for auto-created subnetwork | `string` | `"10.0.0.0/24"` | no |
| signing_key_secret_name | Secret Manager version name for signing key | `string` | `null` | no |
| default_redirect_uris | Default redirect URIs | `list(string)` | `["http://localhost:8000"]` | no |
| groups_overrides | Group override mappings | `map(map(list(string)))` | `{}` | no |
| enable_ipv4 | Enable IPv4 public address | `bool` | `true` | no |
| enable_ipv6 | Enable IPv6 public address | `bool` | `true` | no |
| machine_type | Compute Engine machine type | `string` | `"e2-micro"` | no |
| allowed_cidrs_ipv4 | Allowed IPv4 CIDRs | `list(string)` | `["0.0.0.0/0"]` | no |
| allowed_cidrs_ipv6 | Allowed IPv6 CIDRs | `list(string)` | `["::/0"]` | no |
| connector_hosted_domain | Google hosted domain | `string` | `null` | no |
| connector_github_hostname | GitHub hostname for GHE | `string` | `"github.com"` | no |
| easy_oidc_version | easy-oidc version to install | `string` | `"latest"` | no |
| caddy_version | Caddy version | `string` | `"latest"` | no |
| service_account_email | Existing service account email | `string` | `null` | no |
| grant_secret_accessor | Grant project Secret Manager accessor to service account | `bool` | `true` | no |
| ssh_keys | Optional GCE metadata SSH keys | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| issuer_url | OIDC issuer URL |
| client_ids | List of configured client IDs |
| public_ipv4 | Public IPv4 address |
| public_ipv6 | Public IPv6 address |
| instance_id | Compute Engine instance ID |
| instance_name | Compute Engine instance name |
| subnetwork | Subnetwork used by the instance |
| service_account_email | Instance service account email |
