# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Local Peering Gateways                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

resource "oci_core_local_peering_gateway" "poc_to_dev" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "lpg-poc-to-dev"
  peer_id        = oci_core_local_peering_gateway.dev_to_poc.id
  freeform_tags  = var.freeform_tags
}

resource "oci_core_local_peering_gateway" "dev_to_poc" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "lpg-dev-to-poc"
  freeform_tags  = var.freeform_tags
}
