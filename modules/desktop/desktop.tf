
# Compute: The VM (Elastic Cloud Server)
locals {
  vm_name = "rdesktop1"

  user_data = replace(templatefile("${path.module}/desktop.yaml", {
      user = var.cloud_user.name
      passwd = var.cloud_user.passwd
      ssh_keys = var.cloud_user.ssh_keys
      more_users = var.local_users
      dns_zone = var.dns_zone
      region = var.region
      trust_staging = base64gzip(file("${path.module}/trust-le-staging.sh"))
    }), "\r", "")
}

resource "opentelekomcloud_compute_instance_v2" "desktop_vm" {
  name            = local.vm_name
  flavor_name     = "s9.medium.4"
  security_groups = var.security_groups

  network {
    uuid = var.subnet_id
  }

  # 1. System Disk (Bootable)
  block_device {
    uuid                  = var.stdimg_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 20   # System Disk: 20 GB
    delete_on_termination = true
  }

  # Cloud-init configuration
  user_data = local.user_data
  tags = var.common_tags
}

# Create EIP for desktop VM
resource "opentelekomcloud_vpc_eip_v1" "eip_rdesktop1" {
  publicip {
    type = "5_bgp"
    name = "eip-rdesktop1"
  }
  bandwidth {
    name = "bw-rdesktop1"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
}

# Add DNAT mappings
resource "opentelekomcloud_nat_dnat_rule_v2" "natfw_rdesktop1_22" {
  nat_gateway_id        = var.natgw_id
  floating_ip_id        = opentelekomcloud_vpc_eip_v1.eip_rdesktop1.id
  protocol              = "tcp"
  internal_service_port = 22
  external_service_port = 22
  port_id               = opentelekomcloud_compute_instance_v2.desktop_vm.network[0].port
}

resource "opentelekomcloud_nat_dnat_rule_v2" "natfw_rdesktop1_443" {
  nat_gateway_id        = var.natgw_id
  floating_ip_id        = opentelekomcloud_vpc_eip_v1.eip_rdesktop1.id
  protocol              = "tcp"
  internal_service_port = 443
  external_service_port = 443
  port_id               = opentelekomcloud_compute_instance_v2.desktop_vm.network[0].port
}

# Public DNS records
data "opentelekomcloud_dns_zone_v2" "ext_dns" {
  name = "${var.dns_zone}."
}

resource "opentelekomcloud_dns_recordset_v2" "dns_a_rdesktop_1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "www-${local.vm_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_vpc_eip_v1.eip_rdesktop1.publicip[0].ip_address ]
  tags = var.common_tags
}

# Private DNS records
resource "opentelekomcloud_dns_recordset_v2" "pdns_a_rdesktop_1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "${local.vm_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.desktop_vm.access_ip_v4 ]
  tags = var.common_tags
}

