# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Database Module                                                           ║
# ║  ADB-S (Private Endpoint) + Dev DBCS (Standard)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# AUTONOMOUS DATABASE SERVERLESS — Private Endpoint Access Only
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_database_autonomous_database" "poc_adb" {
  compartment_id = var.poc_compartment_ocid
  display_name   = var.adb_display_name
  db_name        = var.adb_db_name

  # ─── Compute & Storage ──────────────────────────────────────────────────────
  compute_count               = var.adb_cpu_core_count
  data_storage_size_in_gb     = var.adb_data_storage_size_in_gb
  db_workload                 = var.adb_workload
  db_version                  = var.adb_db_version
  license_model               = var.adb_license_model
  is_auto_scaling_enabled     = true
  is_auto_scaling_for_storage_enabled = false

  # ─── Private Endpoint Configuration (CRITICAL) ─────────────────────────────
  # This sets the database to Private Endpoint Access Only.
  # No public endpoint will be created. Cannot be changed post-provisioning.
  subnet_id      = var.adb_subnet_id
  nsg_ids        = [var.nsg_adb_private_id]

  # ─── mTLS / TLS ────────────────────────────────────────────────────────────
  is_mtls_connection_required = var.adb_is_mtls_required

  # ─── Access Control List (Section 7.2 of the reference doc) ────────────────
  # Permits inbound connections from the OAC PAC subnet.
  # Without this, ADB-S rejects OAC connections even with correct routing.
  is_access_control_enabled = true

  whitelisted_ips = [var.oac_pac_subnet_cidr]

  # ─── Credentials ───────────────────────────────────────────────────────────
  admin_password = var.adb_admin_password

  # ─── Tags ──────────────────────────────────────────────────────────────────
  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [
      admin_password,
      # Prevent Terraform from destroying/recreating on credential rotation
    ]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEV DBCS — Standard Oracle Database System
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_database_db_system" "dev_dbcs" {
  compartment_id      = var.dev_compartment_ocid
  availability_domain = var.ad_name
  display_name        = var.dbcs_display_name

  # ─── Compute Shape ─────────────────────────────────────────────────────────
  shape = var.dbcs_shape

  shape_config {
    ocpus = var.dbcs_cpu_core_count
  }

  # ─── Network ───────────────────────────────────────────────────────────────
  subnet_id  = var.dev_db_subnet_id
  hostname   = "devdbcs"
  node_count = var.dbcs_node_count

  # ─── Storage ───────────────────────────────────────────────────────────────
  data_storage_size_in_gb = var.dbcs_storage_size_in_gb
  database_edition        = var.dbcs_db_edition
  license_model           = var.dbcs_license_model
  storage_volume_performance_mode = "BALANCED"

  # ─── SSH Access ────────────────────────────────────────────────────────────
  ssh_public_keys = [var.ssh_public_key]

  # ─── Database Configuration ────────────────────────────────────────────────
  db_home {
    display_name = "${var.dbcs_display_name}-home"
    db_version   = var.dbcs_db_version

    database {
      db_name        = var.dbcs_db_name
      admin_password = var.dbcs_admin_password
      pdb_name       = "devpdb1"

      db_backup_config {
        auto_backup_enabled = false
      }
    }
  }

  # ─── Tags ──────────────────────────────────────────────────────────────────
  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [
      db_home[0].database[0].admin_password,
      ssh_public_keys,
    ]
  }
}
