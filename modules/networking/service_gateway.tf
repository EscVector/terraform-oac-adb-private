# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Service Gateway — Dev VCN                                                ║
# ║  Provides access to OCI services (Object Storage, OS updates, etc.)       ║
# ║  without traversing the public internet.                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  oci_services_id         = data.oci_core_services.all_oci_services.services[0].id
  oci_services_cidr_block = data.oci_core_services.all_oci_services.services[0].cidr_block
}

resource "oci_core_service_gateway" "dev" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "sgw-dev"
  freeform_tags  = var.freeform_tags

  services {
    service_id = local.oci_services_id
  }
}
