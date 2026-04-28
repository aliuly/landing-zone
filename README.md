# Sample Landing Zone on T Cloud Public

OpenTofu/Terraform project that provisions a complete customer
environment on [T Cloud Public (OTC)](https://public.t-cloud.com/en),
including networking, a Jump Server, an Identity Provider (IdP),
and a redundant site-to-site VPN.

## Architecture Overview

```
Internet
   │
   ├── EIP (Jump Server)  ──► rdesktop1 (Jump Server VM)
   ├── EIP (IdP)          ──► idp-vm1   (Identity Provider VM)
   └── EIP × 2 (VPN GW)  ──► Enterprise VPN Gateway
                                  │
                          ┌───────┴───────┐
                          │  vpc-casscust │  (10.183.0.0/16)
                          │               │
                          │  sn-customer-net  (10.183.97.0/24)
                          │  sn-customer-dmz  (10.183.98.0/24)
                          │               │
                          │  NAT Gateway  │──► EIP (outbound)
                          └───────────────┘
                                  │ IPsec tunnels (active/active)
                          ┌───────┴──────────────┐
                      Use case 1              Use case 2
                      (uc1 peer ×2)           (uc2 peer ×2)
```

## Modules

### `modules/basis` — Networking Foundation

Creates the core network infrastructure:

- **VPC** `vpc-casscust` with a configurable CIDR prefix (default `10.183.0.0/16`)
- **Subnets**: `sn-customer-net` (`.97.0/24`) for workloads, `sn-customer-dmz` (`.98.0/24`) for the NAT/VPN gateway
- **NAT Gateway** with a shared EIP for outbound internet access from private instances
- **Outputs**: `vpc_id`, `sn_id`, `dmz_id`, `subnets`, `natgw_id` — consumed by other modules

### `modules/desktop` — Jump Server

Provisions `rdesktop1`, a hardened Ubuntu 22.04 VM that acts as the **Jump Server** for the environment.

- **Flavor**: `s9.medium.4`
- **Dedicated EIP** with DNAT rules forwarding ports 22 and 443 from the public IP to the VM
- **SSH** listening on both port 22 and 443 (useful when firewalls block 22), with `AllowTcpForwarding` and `X11Forwarding` enabled
- **XFCE4 desktop** + XRDP installed for optional graphical remote access
- **Cloud-init** provisions a generic `clouduser` and any additional `local_users` defined in variables
- **Auto-shutdown** timer fires daily at 01:00 to prevent runaway costs
- **CES agent** installed for OTC Cloud Eye monitoring
- DNS records created for both the public (`www-rdesktop1.<dns_zone>`) and private (`rdesktop1.<dns_zone>`) addresses

### `modules/idp` — Identity Provider Server

Provisions `idp-vm1`, a Ubuntu 22.04 VM running an Identity Provider service.

- **Flavor**: `s9.medium.4`
- **Dedicated EIP** with DNAT rules forwarding ports 22, 80, and 443
- **Persistent data disk** (`evs-idp1`, 16 GB SAS) attached at `/dev/vdb` — survives VM rebuilds, preserving TLS certificates and container data
- **Let's Encrypt TLS** certificates obtained via Certbot (an OTC IAM agency `ecs-certbot` is required on the VM for DNS-01 challenges)
- **Split DNS**: external record `www-idp1.<dns_zone>` resolves to the EIP; internal records `idp1.<dns_zone>` and `idp-vm1.<dns_zone>` resolve to the private IP
- `testing_tls` variable switches Certbot to the Let's Encrypt staging environment

### `modules/vpn` — Enterprise VPN

Creates an active/active IPsec VPN gateway connecting the OTC environment to two external sites.

- **Enterprise VPN Gateway** deployed across two availability zones using two dedicated EIPs (`eip-cust-vpngw-1` and `-2`)
- Connects to **two VPN use cases** (`uc1`, `uc2`), each with two redundant tunnels (four tunnels total)
- Peer gateway IPs are resolved at plan time via a `dns2ip` external helper — this allows peer addresses to be managed by DNS rather than hard-coded
- All tunnels use **static routing** with a shared pre-shared key (PSK)
- VPN EIPs have `prevent_destroy = true` to avoid accidental loss of allocated public IPs

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6.0 (or Terraform >= 1.6.0)
- [opentelekomcloud provider](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud) >= 1.35.0
- OTC credentials configured (see **Authentication** below)
- A `dns2ip` helper binary on your `PATH` (used by the VPN module to resolve peer gateway hostnames to IPs)
- A DNS zone already provisioned in OTC DNS (Public Zone)
- An OTC IAM agency named `ecs-certbot` with DNS permissions, assigned to the IdP VM, for Let's Encrypt DNS-01 challenges

## Authentication

The provider block is bare — credentials must be supplied via
environment variables.

Providers are declared using

```hcl
provider "opentelekomcloud" {}
```

This means that credentials should be configured via environment
variables.

### AK/SK credentials

```bash
export OS_ACCESS_KEY="your-access-key"
export OS_SECRET_KEY="your-secret-key"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.

If you are using temporary AK/SK credentials you also need to specify
the security token:

```bash
export OS_SECURITY_TOKEN="your-security-token"
```

### username and password

This is supported as long as you remove the `backend "s3" {}` line from
`versions.tf`

```bash
export OS_USERNAME="your-username"
export OS_PASSWORD="your-password-key"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
export OS_DOMAIN_NAME="OTC-EU-DE-000000000xxxxx"
```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.


## using token

This is supported as long as you remove the `backend "s3" {}` line from
`versions.tf`

```bash
export OS_AUTH_TOKEN="yourtoken"
export OS_PROJECT_NAME="eu-de_project" # or "eu-de" for non-project scoped credentials
export OS_DOMAIN_NAME="OTC-EU-DE-000000000xxxxx"

```
The `tf` script will automatically guess the `OS_AUTH_URL` and
`OS_REGION_NAME` from the `OS_PROJECT_NAME` if they are not specified.


## Configuration

Create a `terraform.tfvars` file (never commit this to version control):

```hcl
# Network
netprefix = "10.183"   # VPC CIDR prefix; results in 10.183.0.0/16

# DNS
dns_zone = "example.com"

# VPN
vpn_psk = "a-strong-pre-shared-key"

peer_subnets = {
  case1 = ["192.168.10.0/24", "192.168.11.0/24"]
  case2 = ["172.16.20.0/24"]
}

# TLS / Let's Encrypt
le_email    = "admin@example.com"
testing_tls = false   # set to true to use LE staging during testing

# Cloud user (used on all VMs)
cloud_user = {
  name     = "clouduser"
  passwd   = "hashed-or-plain-password"
  ssh_keys = ["ssh-ed25519 AAAA... you@host"]
}

# Additional local users
local_users = [
  {
    name     = "alice"
    gecos    = "Alice Example"
    passwd   = "hashed-password"
    ssh_keys = ["ssh-ed25519 AAAA... alice@host"]
  }
]

# Tags applied to all resources
common_tags = {
  environment = "development"
  managed_by  = "OpenTofu"
  CASIO       = "customer"
}
```

### Backend configuration

The default set-up in `versions.tf` include a line:

```hcl
backend "s3" {}
```

This stores `terraform.state` in a S3 compatible bucket.  This
requires AK/SK authentication as recommend in a previous section.
To configure the backend you need to create a file `backend.hcl`:

```hcl
# backend.hcl
bucket                      = "my-tofu-state"
key                         = "customer/terraform.tfstate"
region                      = "eu-de"
endpoint                    = "https://obs.eu-de.otc.t-systems.com"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
force_path_style            = true
use_lockfile                = true
```


## Usage

```sh
# Initialise providers and modules
tofu init

# Preview changes
tofu plan

# Apply
tofu apply

# Tear down (note: VPN EIPs and the IdP data disk have prevent_destroy = true)
tofu destroy
```

> **Note:** The VPN EIPs (`eip-cust-vpngw-1/2`) and the IdP data volume (`evs-idp1`) are protected with `lifecycle { prevent_destroy = true }`. Remove those blocks manually before running `destroy` if you intend to delete them.

## Module Testing

Each module can be tested in isolation. When the root module is applied, it writes a ready-to-use `inputs.tfvars` file into each module directory (`modules/desktop/inputs.tfvars`, `modules/idp/inputs.tfvars`, `modules/vpn/inputs.tfvars`). To test a module standalone:

```sh
cd modules/desktop
tofu init
tofu plan -var-file=inputs.tfvars
```

## DNS Conventions

| Record pattern | Type | Resolves to |
|---|---|---|
| `www-<name>.<dns_zone>` | A | Public EIP |
| `<name>.<dns_zone>` | A | Private IP |
| `www-cust-vpngw-1.<dns_zone>` | A | VPN EIP 1 |
| `www-cust-vpngw-2.<dns_zone>` | A | VPN EIP 2 |

Internal hosts use the short name; external access uses the `www-` prefixed name.

## File Structure

```
.
├── basis.tf          # Instantiates the basis (network) module
├── common.tf         # Shared data sources (OS image lookup)
├── desktop.tf        # Jump Server module instantiation + test helper
├── idp.tf            # IdP module instantiation + test helper
├── idp_volume.tf     # Persistent data volume for IdP
├── provider.tf       # Provider + credential variable
├── secgrp.tf         # Security groups (Jump Server and IdP)
├── variables.tf      # Root-level input variables
├── version.tf        # Required provider versions
├── vpn.tf            # VPN module instantiation + test helper
├── vpn_eip.tf        # VPN gateway EIPs and their DNS records
└── modules/
    ├── basis/        # VPC, subnets, NAT gateway
    ├── desktop/      # Jump Server VM + cloud-init
    ├── idp/          # IdP VM + cloud-init + data disk
    └── vpn/          # Enterprise VPN gateway + tunnels
```

# TODO

* [x] Remove sensitive flags from regions calculated from otc credentials
  nonsensitive(variable)
* [x] nginx configuration to include internal host
* [x] add domain to resolve list
* [x] idp should request a TLS certificate for internal host
* [x] move idp data volumes to its own volume so we can re-build
  and keep data.
  - move IDP data
  - Keep TLS certs here
- [ ] configure logtank service

***

* External hosts are www-name, internal hosts just name.

# More work
- [ ] split-horizon DNS (internal vs. external zones)
- [ ] rdesktop => jumpserver
- [ ] Compliance as code hardening

