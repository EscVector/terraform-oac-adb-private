# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  DHCP Options (VCN Default DNS Resolver)                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

resource "oci_core_dhcp_options" "poc_dhcp" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "dhcp-poc-private"
  freeform_tags  = var.freeform_tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["pocvcn.oraclevcn.com"]
  }
}

resource "oci_core_dhcp_options" "dev_dhcp" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "dhcp-dev-private"
  freeform_tags  = var.freeform_tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["devvcn.oraclevcn.com"]
  }
}
