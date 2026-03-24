# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  VCNs — POC and Dev                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

resource "oci_core_vcn" "poc" {
  compartment_id = var.poc_compartment_ocid
  cidr_blocks    = [var.poc_vcn_cidr]
  display_name   = var.poc_vcn_display_name
  dns_label      = "pocvcn"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_vcn" "dev" {
  compartment_id = var.dev_compartment_ocid
  cidr_blocks    = [var.dev_vcn_cidr]
  display_name   = var.dev_vcn_display_name
  dns_label      = "devvcn"
  freeform_tags  = var.freeform_tags
}
