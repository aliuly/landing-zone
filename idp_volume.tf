#
# IdP persistent data
# - mainly to persist TLS certificates and container data
#
resource "opentelekomcloud_blockstorage_volume_v2" "data_idp" {
  name = "evs-idp1"
  size = 16 # GB
  lifecycle {
    prevent_destroy = true
  }
  volume_type = "SAS"
  tags = var.common_tags
}

