
# Networking: Virtual Private Cloud (VPC)
resource "opentelekomcloud_vpc_v1" "vpc" {
  name = "vpc-casscust"
  cidr = "${var.netprefix}.0.0/16"
  tags = var.common_tags
}

# Subnets
resource "opentelekomcloud_vpc_subnet_v1" "sn" {
  name       = "sn-customer-net"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.97.0/24"
  gateway_ip = "${var.netprefix}.97.1"
  tags = var.common_tags
}
resource "opentelekomcloud_vpc_subnet_v1" "dmz" {
  name       = "sn-customer-dmz"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.98.0/24"
  gateway_ip = "${var.netprefix}.98.1"
  tags = var.common_tags
}


#
# shared NAT gateway for internet traffic
#
resource "opentelekomcloud_nat_gateway_v2" "natgw" {
  name                = "natgw-casscust"
  description         = "NAT Gateway for outbound traffic"
  spec                = "0" # "0" is Micro,"1" is Small, "2" Medium, "3" Large, "4" Extra-large
  router_id           = opentelekomcloud_vpc_v1.vpc.id
  internal_network_id = opentelekomcloud_vpc_subnet_v1.dmz.id # The network where the NAT GW resides
  tags = var.common_tags
}

# Create shared EIP for outbound traffic
resource "opentelekomcloud_vpc_eip_v1" "eip_outbound" {
  publicip {
    type = "5_bgp"
    name = "eip-outbound"
  }
  bandwidth {
    name = "bw-outbound"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
}

# Outbound traffic

resource "opentelekomcloud_nat_snat_rule_v2" "subnet1_snat" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.natgw.id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.eip_outbound.id
  network_id     = opentelekomcloud_vpc_subnet_v1.sn.id
}

