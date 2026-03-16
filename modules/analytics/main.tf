# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Analytics Module                                                          ║
# ║  OAC Instance + Private Access Channel (PAC)                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# ORACLE ANALYTICS CLOUD INSTANCE
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_analytics_analytics_instance" "oac" {
  compartment_id = var.poc_compartment_ocid
  name           = replace(var.oac_display_name, "-", "")
  display_name   = var.oac_display_name
  feature_set    = var.oac_feature_set
  license_type   = var.oac_license_type

  idcs_access_token = var.oac_idcs_access_token

  capacity {
    capacity_type  = var.oac_capacity_type
    capacity_value = var.oac_capacity_value
  }

  # OAC network endpoint type — PRIVATE enables PAC configuration
  network_endpoint_details {
    network_endpoint_type = "PRIVATE"
    vcn_id                = var.poc_vcn_id
    subnet_id             = var.oac_pac_subnet_id
    network_security_group_ids = [var.nsg_oac_pac_id]
  }

  freeform_tags = var.freeform_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# PRIVATE ACCESS CHANNEL (PAC)
# ═══════════════════════════════════════════════════════════════════════════════
# The PAC injects a managed VNIC into the OAC PAC subnet, enabling OAC to
# reach private-only resources within the POC VCN.
#
# DNS ZONE CONFIGURATION (Section 8.2 of the reference doc):
# The private_source_dns_zones tell OAC to resolve hostnames in these zones
# using the VCN internal DNS resolver instead of public DNS. Without this,
# OAC cannot resolve the ADB-S private endpoint FQDN.

resource "oci_analytics_analytics_instance_private_access_channel" "pac" {
  analytics_instance_id = oci_analytics_analytics_instance.oac.id
  display_name          = "pac-poc-vcn"
  vcn_id                = var.poc_vcn_id
  subnet_id             = var.oac_pac_subnet_id
  network_security_group_ids = [var.nsg_oac_pac_id]

  # ─── DNS Zone for ADB-S Private Endpoint FQDN Resolution ───────────────────
  # This is the most commonly missed configuration step.
  # Adjust the region slug to match your deployment region.
  private_source_dns_zones {
    dns_zone    = "adb.${var.region}.oraclecloudapps.com"
    description = "ADB-S private endpoint DNS zone"
  }

  # ─── DNS Zone for OCI internal service endpoints ───────────────────────────
  private_source_dns_zones {
    dns_zone    = "oraclevcn.com"
    description = "OCI VCN internal DNS"
  }

  # ─── Optional: Dev DBCS DNS zone (Section 11 — cross-VCN access) ───────────
  # Uncomment if OAC needs direct access to Dev DBCS across the LPG.
  # private_source_dns_zones {
  #   dns_zone    = "devvcn.oraclevcn.com"
  #   description = "Dev VCN internal DNS for DBCS"
  # }
}
