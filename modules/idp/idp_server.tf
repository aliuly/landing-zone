
locals {
  dns_name = "idp1"
  vm_name = "idp-vm1"
  dev_path = "/dev/vdb"
}

# Compute: The VM (Elastic Cloud Server)
resource "opentelekomcloud_compute_instance_v2" "idp_vm" {
  name            =  local.vm_name
  flavor_name     = "s9.medium.4"
  security_groups = var.security_groups
  availability_zone = var.az_name

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
  user_data = replace(templatefile("${path.module}/idp_server.yaml", {
      user = var.cloud_user.name
      passwd = var.cloud_user.passwd
      ssh_keys = var.cloud_user.ssh_keys
      hostname = local.dns_name
      dnsname = "www-${local.dns_name}.${var.dns_zone}"
      intname = "${local.dns_name}.${var.dns_zone}"
      ca_email = var.le_email
      dns_zone = var.dns_zone
      region = var.region
      testing_tls = var.testing_tls
      device_path = local.dev_path
      php_content = file("${path.module}/security_reports.php")
      curler_py = file("${path.module}/curler_py")
      certbot_helper = file("${path.module}/tcloudpublic-cerbot-helper.sh")
    }), "\r", "")
  metadata = {
    agency_name = "ecs-certbot"
  }
  tags = var.common_tags
}

# 3. The Attachment (The "Glue")
resource "opentelekomcloud_compute_volume_attach_v2" "attach" {
  instance_id = opentelekomcloud_compute_instance_v2.idp_vm.id
  volume_id   = var.data_disk_id
  device      = local.dev_path
}

# Create EIP for IdP VM
resource "opentelekomcloud_vpc_eip_v1" "eip_idp" {
  publicip {
    type = "5_bgp"
    name = "eip-idp"
  }
  bandwidth {
    name = "bw-idp"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
}

# Define the ports you want to forward
resource "opentelekomcloud_nat_dnat_rule_v2" "vm_forwarding" {
  # This creates one rule for every port in the list
  for_each = toset([for p in [22,80,443] : tostring(p)])

  nat_gateway_id        = var.natgw_id
  floating_ip_id        = opentelekomcloud_vpc_eip_v1.eip_idp.id
  protocol              = "tcp"
  internal_service_port = each.value
  external_service_port = each.value
  #~ private_ip            = opentelekomcloud_compute_instance_v2.idp_server.access_ip_v4
  port_id               = opentelekomcloud_compute_instance_v2.idp_vm.network[0].port
}

# DNS records
data "opentelekomcloud_dns_zone_v2" "ext_dns" {
  name = "${var.dns_zone}."
}

resource "opentelekomcloud_dns_recordset_v2" "extdns_a_idp" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "www-${local.dns_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_vpc_eip_v1.eip_idp.publicip[0].ip_address ]
  tags = var.common_tags
}

resource "opentelekomcloud_dns_recordset_v2" "intdns_a_vm" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "${local.vm_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.idp_vm.access_ip_v4 ]
  tags = var.common_tags
}

resource "opentelekomcloud_dns_recordset_v2" "intdns_a_idp" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "${local.dns_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.idp_vm.access_ip_v4 ]
  tags = var.common_tags
}

