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

# ─── ADB-S Listener ──────────────────────────────────────────────────────────

variable "adb_is_mtls_required" {
  description = "Whether mTLS is required (true = port 1522, false = port 1521)"
  type        = bool
  default     = true
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
