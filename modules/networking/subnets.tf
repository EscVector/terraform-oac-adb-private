# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Subnets                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── POC VCN: ADB-S Private Endpoint Subnet ──────────────────────────────────

resource "oci_core_subnet" "adb_private" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.adb_subnet_cidr
  display_name               = "private-adb-sub"
  dns_label                  = "adbsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_adb.id
  security_list_ids          = [oci_core_security_list.adb_private.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── POC VCN: OAC PAC Subnet ─────────────────────────────────────────────────

resource "oci_core_subnet" "oac_pac" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.oac_pac_subnet_cidr
  display_name               = "oac-pac-sub"
  dns_label                  = "oacpacsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_oac_pac.id
  security_list_ids          = [oci_core_security_list.oac_pac.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── POC VCN: Compute Subnet ────────────────────────────────────────────────

resource "oci_core_subnet" "poc_compute" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.poc_compute_subnet_cidr
  display_name               = "poc-compute-sub"
  dns_label                  = "poccompsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_compute.id
  security_list_ids          = [oci_core_security_list.poc_compute.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── Dev VCN: Compute Subnet ───────────────────────────────────────────────

resource "oci_core_subnet" "dev_compute" {
  compartment_id             = var.dev_compartment_ocid
  vcn_id                     = oci_core_vcn.dev.id
  cidr_block                 = var.dev_compute_subnet_cidr
  display_name               = "dev-compute-sub"
  dns_label                  = "devcompsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.dev_compute.id
  security_list_ids          = [oci_core_security_list.dev_compute.id]
  dhcp_options_id            = oci_core_dhcp_options.dev_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── Dev VCN: DBCS Subnet ────────────────────────────────────────────────────

resource "oci_core_subnet" "dev_db" {
  compartment_id             = var.dev_compartment_ocid
  vcn_id                     = oci_core_vcn.dev.id
  cidr_block                 = var.dev_db_subnet_cidr
  display_name               = "dev-db-sub"
  dns_label                  = "devdbsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.dev_db.id
  security_list_ids          = [oci_core_security_list.dev_db.id]
  dhcp_options_id            = oci_core_dhcp_options.dev_dhcp.id
  freeform_tags              = var.freeform_tags
}
