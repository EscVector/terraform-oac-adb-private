# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Oracle Base Database (DB System) — Dev Compartment                        ║
# ║  Single-node VM in Dev VCN, connected to POC VCN via LPG.                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

resource "oci_database_db_system" "dev_dbsystem" {
  compartment_id      = var.dev_compartment_ocid
  availability_domain = var.dbsystem_availability_domain
  display_name        = var.dbsystem_display_name
  shape               = var.dbsystem_shape
  cpu_core_count      = var.dbsystem_cpu_core_count
  node_count          = var.dbsystem_node_count
  database_edition    = var.dbsystem_db_edition
  license_model       = var.dbsystem_license_model

  subnet_id       = var.dbsystem_subnet_id
  hostname        = var.dbsystem_hostname
  ssh_public_keys = var.dbsystem_ssh_public_keys

  data_storage_size_in_gb = var.dbsystem_data_storage_size_in_gb

  db_system_options {
    storage_management = var.dbsystem_storage_management
  }

  db_home {
    display_name = var.dbsystem_db_home_display_name

    database {
      db_name        = var.dbsystem_db_name
      pdb_name       = var.dbsystem_pdb_name
      admin_password = var.dbsystem_admin_password

      db_backup_config {
        auto_backup_enabled = var.dbsystem_auto_backup_enabled
      }
    }

    db_version = var.dbsystem_db_version
  }

  freeform_tags = var.freeform_tags

  # Prevent Terraform from attempting to change passwords or storage on every apply
  lifecycle {
    ignore_changes = [
      db_home[0].database[0].admin_password,
      db_home[0].db_version,
      data_storage_size_in_gb,
      cpu_core_count,
      freeform_tags,
      ssh_public_keys,
    ]
  }
}
