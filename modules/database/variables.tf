# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Database Module — Variables                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Compartments ────────────────────────────────────────────────────────────

variable "poc_compartment_ocid" {
  description = "OCID of the POC compartment (ADB-S)"
  type        = string
}

variable "dev_compartment_ocid" {
  description = "OCID of the Dev compartment (Base Database)"
  type        = string
}

# ─── ADB-S (Autonomous Database — POC Compartment) ──────────────────────────

variable "adb_display_name" {
  description = "Display name for the Autonomous Database"
  type        = string
  default     = "POC"
}

variable "adb_db_name" {
  description = "Database name (alphanumeric, max 14 chars)"
  type        = string
  default     = "POC"
}

variable "adb_db_workload" {
  description = "ADB workload type: OLTP, DW, AJD, or APEX"
  type        = string
  default     = "OLTP"
}

variable "adb_db_version" {
  description = "Oracle Database version for ADB"
  type        = string
  default     = "19c"
}

variable "adb_cpu_core_count" {
  description = "Number of ECPU cores for the ADB (0 for ECPU-based billing)"
  type        = number
  default     = 0
}

variable "adb_data_storage_size_in_tbs" {
  description = "Data storage size in TBs"
  type        = number
  default     = 1
}

variable "adb_admin_password" {
  description = "ADMIN password for the ADB (must meet Oracle complexity requirements)"
  type        = string
  sensitive   = true
}

variable "adb_is_mtls_required" {
  description = "Whether mTLS is required (true = port 1522)"
  type        = bool
  default     = true
}

variable "adb_license_model" {
  description = "License model: LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "adb_is_auto_scaling_enabled" {
  description = "Enable auto-scaling for ADB compute"
  type        = bool
  default     = true
}

variable "adb_subnet_id" {
  description = "Subnet OCID for the ADB private endpoint"
  type        = string
}

variable "adb_nsg_ids" {
  description = "List of NSG OCIDs to attach to the ADB private endpoint"
  type        = list(string)
  default     = []
}

# ─── Oracle Base Database (DB System — Dev Compartment) ─────────────────────

variable "dbsystem_display_name" {
  description = "Display name for the DB System"
  type        = string
  default     = "dev-db-system"
}

variable "dbsystem_shape" {
  description = "DB System shape (e.g., VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "dbsystem_cpu_core_count" {
  description = "Number of CPU cores for the DB System"
  type        = number
  default     = 1
}

variable "dbsystem_node_count" {
  description = "Number of nodes (1 for single-node, 2 for RAC)"
  type        = number
  default     = 1
}

variable "dbsystem_db_edition" {
  description = "Database edition: STANDARD_EDITION, ENTERPRISE_EDITION, ENTERPRISE_EDITION_DEVELOPER, etc."
  type        = string
  default     = "ENTERPRISE_EDITION_DEVELOPER"
}

variable "dbsystem_license_model" {
  description = "License model: LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "dbsystem_availability_domain" {
  description = "Availability domain for the DB System"
  type        = string
}

variable "dbsystem_subnet_id" {
  description = "Subnet OCID for the DB System"
  type        = string
}

variable "dbsystem_ssh_public_keys" {
  description = "SSH public keys for DB System access"
  type        = list(string)
}

variable "dbsystem_hostname" {
  description = "Hostname prefix for the DB System"
  type        = string
  default     = "dev"
}

variable "dbsystem_data_storage_size_in_gb" {
  description = "Data storage size in GB for the DB System"
  type        = number
  default     = 50
}

variable "dbsystem_storage_management" {
  description = "Storage management type: ASM or LVM"
  type        = string
  default     = "LVM"
}

variable "dbsystem_db_name" {
  description = "Database name for the initial DB home database"
  type        = string
  default     = "DB0324"
}

variable "dbsystem_db_version" {
  description = "Oracle Database version (e.g., 19.0.0.0)"
  type        = string
  default     = "19.0.0.0"
}

variable "dbsystem_pdb_name" {
  description = "Pluggable database name"
  type        = string
  default     = "DEVPDB"
}

variable "dbsystem_admin_password" {
  description = "SYS/SYSTEM password for the DB System (must meet Oracle complexity requirements)"
  type        = string
  sensitive   = true
}

variable "dbsystem_db_home_display_name" {
  description = "Display name for the DB Home"
  type        = string
  default     = "DB0324"
}

variable "dbsystem_auto_backup_enabled" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

# ─── Tags ────────────────────────────────────────────────────────────────────

variable "freeform_tags" {
  description = "Freeform tags applied to all resources"
  type        = map(string)
  default     = {}
}
