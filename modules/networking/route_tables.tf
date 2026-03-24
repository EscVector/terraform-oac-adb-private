# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Route Tables                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── POC VCN: ADB-S Subnet Route Table ───────────────────────────────────────

resource "oci_core_route_table" "poc_adb" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-adb-private"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG"
  }
}

# ─── POC VCN: OAC PAC Subnet Route Table ─────────────────────────────────────

resource "oci_core_route_table" "poc_oac_pac" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-oac-pac"
  freeform_tags  = var.freeform_tags

  # Note: No default route (0.0.0.0/0) — POC VCN has no internet gateway.
  # Only intra-VCN traffic to ADB-S subnet is needed (implicit local route).
  # LPG route included for optional direct OAC→Dev DBCS connectivity (Section 11).

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG (optional OAC→Dev DBCS)"
  }
}

# ─── Dev VCN: DBCS Subnet Route Table ────────────────────────────────────────

resource "oci_core_route_table" "dev_db" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "rt-dev-private"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.poc_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.dev_to_poc.id
    description       = "Route to POC VCN via LPG"
  }

  route_rules {
    destination       = local.oci_services_cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.dev.id
    description       = "Route to OCI services via Service Gateway"
  }
}

# ─── POC VCN: Compute Subnet Route Table ────────────────────────────────────

resource "oci_core_route_table" "poc_compute" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-compute"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG"
  }
}

# ─── Dev VCN: Compute Subnet Route Table ───────────────────────────────────

resource "oci_core_route_table" "dev_compute" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "rt-dev-compute"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.poc_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.dev_to_poc.id
    description       = "Route to POC VCN via LPG"
  }

  route_rules {
    destination       = local.oci_services_cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.dev.id
    description       = "Route to OCI services via Service Gateway"
  }
}
