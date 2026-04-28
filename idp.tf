#
# Configure IdP server
#
# Unit-testing block
resource "local_file" "idp_inputs" {
  filename = "${path.module}/modules/idp/inputs.tfvars"

  content  = <<-EOT
    security_groups = ${jsonencode([opentelekomcloud_networking_secgroup_v2.sg_idp.name])}
    subnet_id = ${jsonencode(module.basis.sn_id)}
    natgw_id = ${jsonencode(module.basis.natgw_id)}
    stdimg_id = ${jsonencode(data.opentelekomcloud_images_image_v2.std_image.id)}
    cloud_user = ${jsonencode(var.cloud_user)}
    region = ${jsonencode(var.region)}
    dns_zone = ${jsonencode(var.dns_zone)}
    le_email = ${jsonencode(var.le_email)}
    testing_tls = ${jsonencode(var.testing_tls)}

    data_disk_id = ${jsonencode(opentelekomcloud_blockstorage_volume_v2.data_idp.id)}
    az_name = ${jsonencode(opentelekomcloud_blockstorage_volume_v2.data_idp.availability_zone)}
  EOT

  file_permission = "0644"
}

module "idp" {
  source = "./modules/idp"
  common_tags = var.common_tags

  security_groups = [opentelekomcloud_networking_secgroup_v2.sg_idp.name]
  subnet_id = module.basis.sn_id
  natgw_id = module.basis.natgw_id
  stdimg_id = data.opentelekomcloud_images_image_v2.std_image.id
  cloud_user = var.cloud_user
  region = var.region
  dns_zone = var.dns_zone
  le_email = var.le_email
  testing_tls = jsonencode(var.testing_tls)

  data_disk_id = opentelekomcloud_blockstorage_volume_v2.data_idp.id
  az_name = opentelekomcloud_blockstorage_volume_v2.data_idp.availability_zone

}

