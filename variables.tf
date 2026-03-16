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
  default     = "10.0.0.0/16"
}

variable "poc_vcn_display_name" {
  description = "Display name for the POC VCN"
  type        = string
  default     = "poc-vcn"
}

variable "adb_subnet_cidr" {
  description = "CIDR block for the ADB-S private endpoint subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "oac_pac_subnet_cidr" {
  description = "CIDR block for the OAC Private Access Channel subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# ─── Dev VCN ──────────────────────────────────────────────────────────────────

variable "dev_vcn_cidr" {
  description = "CIDR block for the Dev VCN"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dev_vcn_display_name" {
  description = "Display name for the Dev VCN"
  type        = string
  default     = "dev-vcn"
}

variable "dev_db_subnet_cidr" {
  description = "CIDR block for the Dev DBCS subnet"
  type        = string
  default     = "10.1.1.0/24"
}

# ─── ADB-S Configuration ─────────────────────────────────────────────────────

variable "adb_display_name" {
  description = "Display name for the Autonomous Database"
  type        = string
  default     = "pocadb"
}

variable "adb_db_name" {
  description = "Database name for the ADB-S (alphanumeric, max 14 chars)"
  type        = string
  default     = "pocadb"
}

variable "adb_admin_password" {
  description = "ADMIN password for ADB-S (min 12 chars, 1 upper, 1 lower, 1 number)"
  type        = string
  sensitive   = true
}

variable "adb_cpu_core_count" {
  description = "Number of ECPU cores for ADB-S"
  type        = number
  default     = 2
}

variable "adb_data_storage_size_in_gb" {
  description = "Storage size in GB for ADB-S"
  type        = number
  default     = 20
}

variable "adb_workload" {
  description = "ADB-S workload type: OLAP (ADW) or OLTP (ATP)"
  type        = string
  default     = "OLAP"

  validation {
    condition     = contains(["OLAP", "OLTP"], var.adb_workload)
    error_message = "adb_workload must be OLAP (ADW) or OLTP (ATP)."
  }
}

variable "adb_license_model" {
  description = "License model: LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "adb_is_mtls_required" {
  description = "Whether mTLS is required (true = port 1522, false = port 1521)"
  type        = bool
  default     = true
}

variable "adb_db_version" {
  description = "Oracle Database version for ADB-S"
  type        = string
  default     = "19c"
}

# ─── OAC Configuration ───────────────────────────────────────────────────────

variable "oac_display_name" {
  description = "Display name for the OAC instance"
  type        = string
  default     = "poc-oac"
}

variable "oac_capacity_type" {
  description = "OAC capacity type: OLPU_COUNT"
  type        = string
  default     = "OLPU_COUNT"
}

variable "oac_capacity_value" {
  description = "Number of OLPUs for OAC"
  type        = number
  default     = 2
}

variable "oac_feature_set" {
  description = "OAC feature set: ENTERPRISE_ANALYTICS or SELF_SERVICE_ANALYTICS"
  type        = string
  default     = "ENTERPRISE_ANALYTICS"
}

variable "oac_license_type" {
  description = "OAC license type: LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "oac_idcs_access_token" {
  description = "IDCS access token for OAC provisioning"
  type        = string
  sensitive   = true
}

# ─── Dev DBCS Configuration ──────────────────────────────────────────────────

variable "dbcs_display_name" {
  description = "Display name for the Dev DB System"
  type        = string
  default     = "dev-dbcs"
}

variable "dbcs_shape" {
  description = "Compute shape for the DBCS instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "dbcs_cpu_core_count" {
  description = "Number of CPU cores for the DBCS instance"
  type        = number
  default     = 2
}

variable "dbcs_db_edition" {
  description = "Database edition: STANDARD_EDITION or ENTERPRISE_EDITION"
  type        = string
  default     = "ENTERPRISE_EDITION"
}

variable "dbcs_admin_password" {
  description = "SYS/SYSTEM password for DBCS"
  type        = string
  sensitive   = true
}

variable "dbcs_db_name" {
  description = "Database name for the DBCS (alphanumeric, max 8 chars)"
  type        = string
  default     = "devdb"
}

variable "dbcs_db_version" {
  description = "Oracle Database version for DBCS"
  type        = string
  default     = "19.0.0.0"
}

variable "dbcs_storage_size_in_gb" {
  description = "Data storage size in GB for DBCS"
  type        = number
  default     = 256
}

variable "dbcs_node_count" {
  description = "Number of database nodes (1 for single, 2 for RAC)"
  type        = number
  default     = 1
}

variable "dbcs_license_model" {
  description = "License model: LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE"
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "ssh_public_key" {
  description = "SSH public key for DBCS node access"
  type        = string
}

# ─── IAM ──────────────────────────────────────────────────────────────────────

variable "analytics_admin_group_name" {
  description = "Name of the IAM group for OAC administrators"
  type        = string
  default     = "AnalyticsAdmins"
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
