variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "customer"
  }
}


# For basis configuration
variable "netprefix" {
  description = "Network prefix to use for CIDR (VPCs are assumed to be Class-C's)"
  default = "10.183"
  type = string
}

variable "region" {
  description = "Region where we are deploying resources"
  type = string
}

# For VPN configuration
variable "vpn_psk" {
  description = "Used to secure VPN links"
  type = string
  sensitive = true
}

variable "peer_subnets" {
  type = map(list(string))
  description = "Networks on the far end of the VPN"
}

# Configure on Linux systems
variable "local_users" {
  description = "Set of sample users to create"
  sensitive = true
  type = list(object({
    name = string
    gecos = optional(string,"")
    passwd = string
    ssh_keys = optional(list(string),[])
  }))
}

variable "cloud_user" {
  description = "Credentials for a generic cloud user"
  type = object({
    name = optional(string, "clouduser")
    passwd = string
    ssh_keys = optional(list(string), [])
  })
  sensitive = true
  default = { passwd = "x" }
}

variable "dns_zone" {
  description = "DNS zone to use"
  type = string
}

# Used for Let's encrypt certificates
variable "le_email" {
  description = "E-Mail address to send to Let's Encrypt"
  type = string
}
variable "testing_tls" {
  description = "Test TLS cert requests"
  type = bool
  default = false
}

