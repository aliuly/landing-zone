output "vpc_id" {
  value = opentelekomcloud_vpc_v1.vpc.id
}

output "dmz_id" {
  value = opentelekomcloud_vpc_subnet_v1.dmz.id
}

output "sn_id" {
  value = opentelekomcloud_vpc_subnet_v1.sn.id
}

output "subnets" {
  value = [
    opentelekomcloud_vpc_subnet_v1.sn.cidr,
    opentelekomcloud_vpc_subnet_v1.dmz.cidr,
  ]
}

output "natgw_id" {
  value = opentelekomcloud_nat_gateway_v2.natgw.id
}
