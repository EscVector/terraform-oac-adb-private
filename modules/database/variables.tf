variable "poc_compartment_ocid" { type = string }
variable "dev_compartment_ocid" { type = string }
variable "ad_name" { type = string }

# ADB-S
variable "adb_subnet_id" { type = string }
variable "nsg_adb_private_id" { type = string }
variable "oac_pac_subnet_cidr" { type = string }
variable "adb_display_name" { type = string }
variable "adb_db_name" { type = string }
variable "adb_admin_password" { type = string }
variable "adb_cpu_core_count" { type = number }
variable "adb_data_storage_size_in_gb" { type = number }
variable "adb_workload" { type = string }
variable "adb_license_model" { type = string }
variable "adb_is_mtls_required" { type = bool }
variable "adb_db_version" { type = string }
variable "poc_vcn_id" { type = string }

# DBCS
variable "dev_db_subnet_id" { type = string }
variable "dbcs_display_name" { type = string }
variable "dbcs_shape" { type = string }
variable "dbcs_cpu_core_count" { type = number }
variable "dbcs_db_edition" { type = string }
variable "dbcs_admin_password" { type = string }
variable "dbcs_db_name" { type = string }
variable "dbcs_db_version" { type = string }
variable "dbcs_storage_size_in_gb" { type = number }
variable "dbcs_node_count" { type = number }
variable "dbcs_license_model" { type = string }
variable "ssh_public_key" { type = string }

variable "freeform_tags" { type = map(string) }
