# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Autonomous Database Serverless (ADB-S) — POC Compartment                 ║
# ║  Private endpoint in POC VCN, accessed via OAC PAC and Bastion.           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

resource "oci_database_autonomous_database" "poc_adb" {
  compartment_id = var.poc_compartment_ocid
  display_name   = var.adb_display_name
  db_name        = var.adb_db_name
  db_workload    = var.adb_db_workload
  db_version     = var.adb_db_version

  compute_count            = var.adb_compute_count
  compute_model            = "ECPU"
  data_storage_size_in_gb  = var.adb_data_storage_size_in_gb
  admin_password           = var.adb_admin_password

  is_mtls_connection_required    = var.adb_is_mtls_required
  license_model                  = var.adb_license_model
  is_auto_scaling_enabled        = var.adb_is_auto_scaling_enabled
  backup_retention_period_in_days = 1

  # Private endpoint configuration
  subnet_id = var.adb_subnet_id
  nsg_ids   = var.adb_nsg_ids

  freeform_tags = var.freeform_tags

  # Prevent Terraform from attempting to change the admin password on every apply
  lifecycle {
    ignore_changes = [
      admin_password,
      db_version,
      freeform_tags,
    ]
  }
}
