# Desktop security group
resource "opentelekomcloud_networking_secgroup_v2" "sg_rdesktop" {
  name        = "sg-rdesktop-access"
  description = "Allow SSH and HTTP(S)"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "rdesktop_allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_rdesktop.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "rdesktop_allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_rdesktop.id
}

# IdP
resource "opentelekomcloud_networking_secgroup_v2" "sg_idp" {
  name        = "sg-idp-access"
  description = "Allow SSH and HTTP(S)"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "idp_allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_idp.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "idp_allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_idp.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "idp_allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_idp.id
}
