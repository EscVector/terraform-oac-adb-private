# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  IAM Module                                                                ║
# ║  Required Policies for OAC PAC + ADB-S Private Endpoint                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Resolve compartment name for policy statements ───────────────────────────

data "oci_identity_compartment" "poc" {
  id = var.poc_compartment_ocid
}

locals {
  poc_compartment_name = data.oci_identity_compartment.poc.name
}

# ═══════════════════════════════════════════════════════════════════════════════
# OAC SERVICE POLICIES (Section 3.2 of the reference doc)
# These are MANDATORY. Without them, PAC creation fails silently.
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_identity_policy" "analytics_service" {
  compartment_id = var.tenancy_ocid
  name           = "oac-service-network-policy"
  description    = "Allow OAC service to create and manage PAC VNICs in POC compartment"

  statements = [
    "allow service analytics to use virtual-network-family in compartment ${local.poc_compartment_name}",
    "allow service analytics to manage vnics in compartment ${local.poc_compartment_name}",
    "allow service analytics to use subnets in compartment ${local.poc_compartment_name}",
    "allow service analytics to use network-security-groups in compartment ${local.poc_compartment_name}",
  ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# OAC ADMIN GROUP POLICIES
# Grants the AnalyticsAdmins group permission to manage OAC instances
# and the underlying network resources needed for PAC.
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_identity_policy" "analytics_admins" {
  compartment_id = var.tenancy_ocid
  name           = "oac-admin-policy"
  description    = "Allow AnalyticsAdmins to manage OAC and networking in POC compartment"

  statements = [
    "allow group ${var.analytics_admin_group_name} to manage analytics-instances in compartment ${local.poc_compartment_name}",
    "allow group ${var.analytics_admin_group_name} to manage virtual-network-family in compartment ${local.poc_compartment_name}",
    "allow group ${var.analytics_admin_group_name} to read autonomous-database-family in compartment ${local.poc_compartment_name}",
    "allow group ${var.analytics_admin_group_name} to use vnics in compartment ${local.poc_compartment_name}",
    "allow group ${var.analytics_admin_group_name} to use subnets in compartment ${local.poc_compartment_name}",
    "allow group ${var.analytics_admin_group_name} to use network-security-groups in compartment ${local.poc_compartment_name}",
  ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUTONOMOUS DATABASE POLICIES
# Allows ADB-S to access VCN resources for private endpoint attachment.
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_identity_policy" "adb_network" {
  compartment_id = var.tenancy_ocid
  name           = "adb-private-endpoint-network-policy"
  description    = "Allow ADB-S service to attach private endpoints in POC compartment"

  statements = [
    "allow service database to use virtual-network-family in compartment ${local.poc_compartment_name}",
    "allow service database to use vnics in compartment ${local.poc_compartment_name}",
    "allow service database to use subnets in compartment ${local.poc_compartment_name}",
    "allow service database to use network-security-groups in compartment ${local.poc_compartment_name}",
  ]
}
