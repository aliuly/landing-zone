#
# Configure Test desktop system
#
# Unit-testing block
resource "local_file" "desktop_inputs" {
  filename = "${path.module}/modules/desktop/inputs.tfvars"

  content  = <<-EOT
    security_groups = ${jsonencode([opentelekomcloud_networking_secgroup_v2.sg_rdesktop.name])}
    subnet_id = ${jsonencode(module.basis.sn_id)}
    natgw_id = ${jsonencode(module.basis.natgw_id)}
    stdimg_id = ${jsonencode(data.opentelekomcloud_images_image_v2.std_image.id)}
    cloud_user = ${jsonencode(var.cloud_user)}
    local_users = ${jsonencode(var.local_users)}
    region = ${jsonencode(var.region)}
    dns_zone = ${jsonencode(var.dns_zone)}
  EOT

  file_permission = "0644"
}

module "desktop" {
  source = "./modules/desktop"
  common_tags = var.common_tags

  security_groups = [opentelekomcloud_networking_secgroup_v2.sg_rdesktop.name]
  subnet_id = module.basis.sn_id
  natgw_id = module.basis.natgw_id
  stdimg_id = data.opentelekomcloud_images_image_v2.std_image.id
  cloud_user = var.cloud_user
  local_users = var.local_users
  region = var.region
  dns_zone = var.dns_zone


}

