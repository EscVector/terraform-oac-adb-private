# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  OAC Private Endpoint ADB-S Connectivity — Variables                       ║
# ║  Terraform Configuration for POC VCN / Dev VCN / LPG Topology             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Provider / Tenancy ───────────────────────────────────────────────────────

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user (omit if using instance principal)"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "API key fingerprint (omit if using instance principal)"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to the OCI API private key (omit if using instance principal)"
  type        = string
  default     = null
}

variable "region" {
  description = "OCI region identifier (e.g., us-ashburn-1)"
  type        = string
  default     = "us-ashburn-1"
}

# ─── IAM ─────────────────────────────────────────────────────────────────────

variable "admin_group_name" {
  description = "Name of the IAM group to grant networking and compute policies"
  type        = string
  default     = "Administrators"
}

# ─── Compartments ─────────────────────────────────────────────────────────────

variable "poc_compartment_ocid" {
  description = "OCID of the compartment for POC resources (ADB-S, OAC, POC VCN)"
  type        = string
}

variable "dev_compartment_ocid" {
  description = "OCID of the compartment for Dev resources (DBCS, Dev VCN)"
  type        = string
}

# ─── POC VCN ──────────────────────────────────────────────────────────────────

variable "poc_vcn_cidr" {
  description = "CIDR block for the POC VCN"
  type        = string
  default     = "192.168.0.0/24"
}

variable "poc_vcn_display_name" {
  description = "Display name for the POC VCN"
  type        = string
  default     = "poc-vcn"
}

variable "adb_subnet_cidr" {
  description = "CIDR block for the ADB-S private endpoint subnet"
  type        = string
  default     = "192.168.0.0/26"
}

variable "oac_pac_subnet_cidr" {
  description = "CIDR block for the OAC Private Access Channel subnet"
  type        = string
  default     = "192.168.0.64/26"
}

# ─── Dev VCN ──────────────────────────────────────────────────────────────────

variable "dev_vcn_cidr" {
  description = "CIDR block for the Dev VCN"
  type        = string
  default     = "192.168.1.0/24"
}

variable "dev_vcn_display_name" {
  description = "Display name for the Dev VCN"
  type        = string
  default     = "dev-vcn"
}

variable "dev_db_subnet_cidr" {
  description = "CIDR block for the Dev DBCS subnet"
  type        = string
  default     = "192.168.1.0/26"
}

# ─── Compute Subnets ─────────────────────────────────────────────────────────

variable "poc_compute_subnet_cidr" {
  description = "CIDR block for the POC compute subnet"
  type        = string
  default     = "192.168.0.128/26"
}

variable "dev_compute_subnet_cidr" {
  description = "CIDR block for the Dev compute subnet"
  type        = string
  default     = "192.168.1.64/26"
}

# ─── Compute Instances ──────────────────────────────────────────────────────

variable "instance_shape" {
  description = "Compute shape for instances"
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "instance_shape_ocpus" {
  description = "Number of OCPUs for flex shape"
  type        = number
  default     = 1
}

variable "instance_shape_memory_in_gbs" {
  description = "Memory in GBs for flex shape"
  type        = number
  default     = 16
}

variable "instance_image_ocid" {
  description = "OCID of the compute image (Oracle Linux)"
  type        = string
}

# ─── Bastion ────────────────────────────────────────────────────────────────

variable "bastion_client_cidr_allow_list" {
  description = "CIDR blocks allowed to connect to the bastion (e.g. your public IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_max_session_ttl" {
  description = "Maximum session TTL in seconds for bastion sessions (default 3 hours)"
  type        = number
  default     = 10800
}

# ─── ADB-S (Autonomous Database — POC) ──────────────────────────────────────

variable "adb_is_mtls_required" {
  description = "Whether mTLS is required (true = port 1522, false = port 1521)"
  type        = bool
  default     = true
}

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

variable "adb_compute_count" {
  description = "Number of ECPUs for the ADB (minimum 2)"
  type        = number
  default     = 2
}

variable "adb_data_storage_size_in_gb" {
  description = "Data storage size in GB (minimum 20)"
  type        = number
  default     = 20
}

variable "adb_admin_password" {
  description = "ADMIN password for the ADB (must meet Oracle complexity requirements)"
  type        = string
  sensitive   = true
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

# ─── Oracle Base Database (DB System — Dev) ─────────────────────────────────

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

# ─── Tags ─────────────────────────────────────────────────────────────────────

variable "freeform_tags" {
  description = "Freeform tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "POC"
    Project     = "OAC-ADB-Private-Endpoint"
    ManagedBy   = "Terraform"
  }
}
