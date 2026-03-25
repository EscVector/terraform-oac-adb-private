# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Database Module — Outputs                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── ADB-S ──────────────────────────────────────────────────────────────────

output "adb_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.poc_adb.id
}

output "adb_private_endpoint_ip" {
  description = "Private endpoint IP of the ADB"
  value       = oci_database_autonomous_database.poc_adb.private_endpoint_ip
}

output "adb_private_endpoint_label" {
  description = "Private endpoint DNS label of the ADB"
  value       = oci_database_autonomous_database.poc_adb.private_endpoint_label
}

output "adb_connection_strings" {
  description = "ADB connection strings"
  value       = oci_database_autonomous_database.poc_adb.connection_strings
}

output "adb_service_console_url" {
  description = "ADB service console URL"
  value       = oci_database_autonomous_database.poc_adb.service_console_url
}

# ─── Oracle Base Database (DB System) ───────────────────────────────────────

output "dbsystem_id" {
  description = "OCID of the DB System"
  value       = oci_database_db_system.dev_dbsystem.id
}

output "dbsystem_hostname" {
  description = "Hostname of the DB System"
  value       = oci_database_db_system.dev_dbsystem.hostname
}

output "dbsystem_listener_port" {
  description = "Listener port of the DB System"
  value       = 1521
}
