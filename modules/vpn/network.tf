

# Our Gateway
resource "opentelekomcloud_enterprise_vpn_gateway_v5" "vpngw" {
  name           = "vpngw-customer"
  vpc_id         = var.vpc_id
  flavor         = "Basic"

  local_subnets  = var.subnets
  connect_subnet = var.dmz_id

  availability_zones = [
    "${var.region}-01",
    "${var.region}-02"
  ]

  eip1 {
    id = var.eip_1
  }
  eip2 {
    id = var.eip_2
  }
  tags = var.common_tags
}

locals {
  usecase1_dnsname = "uc1"
  usecase2_dnsname = "uc2"
}

#####################################################################
# Use case 1 VPN

data "external" "vpnpeer_case1_1" {
  program = [ "dns2ip", "www-${local.usecase1_dnsname}-1.${var.dns_zone}", "10.0.1.1" ]
}
data "external" "vpnpeer_case1_2" {
  program = [ "dns2ip", "www-${local.usecase1_dnsname}-2.${var.dns_zone}", "10.0.1.2" ]
}


resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_case1_1" {
  name     = "vpnpeer-case1-1"
  id_type  = "ip"
  id_value = data.external.vpnpeer_case1_1.result["value"]
  tags = var.common_tags
}

resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_case1_2" {
  name     = "vpnpeer-case1-2"
  id_type  = "ip"
  id_value = data.external.vpnpeer_case1_2.result["value"]
  tags = var.common_tags
}

# Connect the VPNs
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_case1_1" {
  name                = "tunnel-case1-1"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip1[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_case1_1.id
  peer_subnets        = var.peer_subnets.case1
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_case1_2" {
  name                = "tunnel-case1-2"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip2[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_case1_2.id
  peer_subnets        = var.peer_subnets.case1
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}


#####################################################################
# Use case 2 VPN
data "external" "vpnpeer_case2_1" {
  program = [ "dns2ip", "www-${local.usecase2_dnsname}-1.${var.dns_zone}", "10.0.2.1" ]
}
data "external" "vpnpeer_case2_2" {
  program = [ "dns2ip", "www-${local.usecase2_dnsname}-2.${var.dns_zone}", "10.0.2.2" ]
}

# Use case 2 gateways
resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_case2_1" {
  name     = "vpnpeer-case2-1"
  id_type  = "ip"
  id_value = data.external.vpnpeer_case2_1.result["value"]
  tags = var.common_tags
}

resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_case2_2" {
  name     = "vpnpeer-case2-2"
  id_type  = "ip"
  id_value = data.external.vpnpeer_case2_2.result["value"]
  tags = var.common_tags
}


# Connect the VPNs
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_case2_1" {
  name                = "tunnel-case2-1"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip1[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_case2_1.id
  peer_subnets        = var.peer_subnets.case2
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_case2_2" {
  name                = "tunnel-case2-2"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip2[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_case2_2.id
  peer_subnets        = var.peer_subnets.case2
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}

