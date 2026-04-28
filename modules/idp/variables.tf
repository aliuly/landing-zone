#
# Inputs for IdP module
#
variable "security_groups" {
  description = "In what groups to place the IdP"
  type = list(string)
}

variable "subnet_id" {
  description = "Subnet where to place the IdP"
  type = string
}

variable "natgw_id" {
  description = "NATGW we use for IdP"
  type = string
}

variable "stdimg_id" {
  description = "Standard OS image to use"
  type = string
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

variable "region" {
  description = "Region hosting us"
  type = string
}

variable "le_email" {
  description = "E-Mail address to send to Let's Encrypt"
  type = string
}

variable "testing_tls" {
  description = "Test TLS cert requests"
  type = bool
  default = false
}

variable "data_disk_id" {
  description = "Data disk for persistent data"
  type = string
}
variable "az_name" {
  description = "Make sure the data disk az matches us"
  type = string
}

#
# Generics
#
variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "customer"
  }
}
