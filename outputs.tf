# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Outputs — Validation Reference (maps to Section 10 checklist)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Networking ───────────────────────────────────────────────────────────────

output "poc_vcn_id" {
  description = "OCID of the POC VCN"
  value       = module.networking.poc_vcn_id
}

output "dev_vcn_id" {
  description = "OCID of the Dev VCN"
  value       = module.networking.dev_vcn_id
}

output "lpg_peering_status" {
  description = "LPG peering status (should be PEERED)"
  value       = module.networking.lpg_peering_status
}

# ─── ADB-S ────────────────────────────────────────────────────────────────────

output "adb_id" {
  description = "OCID of the Autonomous Database"
  value       = module.database.adb_id
}

output "adb_private_endpoint" {
  description = "ADB-S private endpoint hostname"
  value       = module.database.adb_private_endpoint
}

output "adb_private_endpoint_ip" {
  description = "ADB-S private endpoint IP address"
  value       = module.database.adb_private_endpoint_ip
}

output "adb_connection_strings" {
  description = "ADB-S connection strings (verify tnsnames reference private FQDN)"
  value       = module.database.adb_connection_strings
  sensitive   = true
}

# ─── OAC ──────────────────────────────────────────────────────────────────────

output "oac_id" {
  description = "OCID of the OAC instance"
  value       = module.analytics.oac_id
}

output "oac_service_url" {
  description = "OAC console URL"
  value       = module.analytics.oac_service_url
}

output "pac_ip_address" {
  description = "PAC egress IP (should be within oac-pac-sub CIDR)"
  value       = module.analytics.pac_ip_address
}

# ─── Dev DBCS ─────────────────────────────────────────────────────────────────

output "dbcs_id" {
  description = "OCID of the Dev DB System"
  value       = module.database.dbcs_id
}

output "dbcs_hostname" {
  description = "Hostname of the Dev DBCS node"
  value       = module.database.dbcs_hostname
}

# ─── Validation Summary ──────────────────────────────────────────────────────

output "validation_checklist" {
  description = "Quick reference — verify these post-apply"
  value = {
    "1_lpg_peering"        = module.networking.lpg_peering_status
    "2_adb_private_ep"     = module.database.adb_private_endpoint
    "3_adb_private_ip"     = module.database.adb_private_endpoint_ip
    "4_pac_egress_ip"      = module.analytics.pac_ip_address
    "5_oac_url"            = module.analytics.oac_service_url
  }
}
