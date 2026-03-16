output "adb_id" { value = oci_database_autonomous_database.poc_adb.id }
output "adb_display_name" { value = oci_database_autonomous_database.poc_adb.display_name }
output "adb_private_endpoint" { value = oci_database_autonomous_database.poc_adb.private_endpoint }
output "adb_private_endpoint_ip" { value = oci_database_autonomous_database.poc_adb.private_endpoint_ip }

output "adb_connection_strings" {
  value = oci_database_autonomous_database.poc_adb.connection_strings
}

output "dbcs_id" { value = oci_database_db_system.dev_dbcs.id }
output "dbcs_display_name" { value = oci_database_db_system.dev_dbcs.display_name }
output "dbcs_hostname" { value = oci_database_db_system.dev_dbcs.hostname }
