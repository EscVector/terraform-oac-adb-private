# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  OAC Private Endpoint ADB-S Connectivity — Root Module                     ║
# ║                                                                            ║
# ║  Topology: OAC PAC → POC VCN (ADB-S PE) ←→ LPG ←→ Dev VCN (DBCS)         ║
# ║                                                                            ║
# ║  Deploy order (handled by Terraform dependency graph):                     ║
# ║    1. IAM Policies                                                         ║
# ║    2. Networking (VCNs, LPGs, Subnets, Security Lists, NSGs, Routes)       ║
# ║    3. Databases (ADB-S Private Endpoint + Dev DBCS)                        ║
# ║    4. Analytics (OAC Instance + Private Access Channel)                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 1. IAM POLICIES
# Must be created before any service resources to avoid silent PAC failures.
# ═══════════════════════════════════════════════════════════════════════════════

module "iam" {
  source = "./modules/iam"

  tenancy_ocid               = var.tenancy_ocid
  poc_compartment_ocid       = var.poc_compartment_ocid
  analytics_admin_group_name = var.analytics_admin_group_name
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. NETWORKING
# POC VCN + Dev VCN + LPG Peering + Security Lists + Route Tables + NSGs
# ═══════════════════════════════════════════════════════════════════════════════

module "networking" {
  source = "./modules/networking"

  poc_compartment_ocid = var.poc_compartment_ocid
  dev_compartment_ocid = var.dev_compartment_ocid

  poc_vcn_cidr         = var.poc_vcn_cidr
  poc_vcn_display_name = var.poc_vcn_display_name
  dev_vcn_cidr         = var.dev_vcn_cidr
  dev_vcn_display_name = var.dev_vcn_display_name

  adb_subnet_cidr     = var.adb_subnet_cidr
  oac_pac_subnet_cidr = var.oac_pac_subnet_cidr
  dev_db_subnet_cidr  = var.dev_db_subnet_cidr

  adb_listener_port = local.adb_listener_port
  freeform_tags     = var.freeform_tags

  depends_on = [module.iam]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. DATABASES
# ADB-S (Private Endpoint Only) + Dev DBCS (Standard)
# ═══════════════════════════════════════════════════════════════════════════════

module "database" {
  source = "./modules/database"

  # Compartments
  poc_compartment_ocid = var.poc_compartment_ocid
  dev_compartment_ocid = var.dev_compartment_ocid
  ad_name              = local.ad_name

  # ADB-S
  poc_vcn_id                  = module.networking.poc_vcn_id
  adb_subnet_id               = module.networking.adb_subnet_id
  nsg_adb_private_id          = module.networking.nsg_adb_private_id
  oac_pac_subnet_cidr         = var.oac_pac_subnet_cidr
  adb_display_name            = var.adb_display_name
  adb_db_name                 = var.adb_db_name
  adb_admin_password          = var.adb_admin_password
  adb_cpu_core_count          = var.adb_cpu_core_count
  adb_data_storage_size_in_gb = var.adb_data_storage_size_in_gb
  adb_workload                = var.adb_workload
  adb_license_model           = var.adb_license_model
  adb_is_mtls_required        = var.adb_is_mtls_required
  adb_db_version              = var.adb_db_version

  # DBCS
  dev_db_subnet_id    = module.networking.dev_db_subnet_id
  dbcs_display_name   = var.dbcs_display_name
  dbcs_shape          = var.dbcs_shape
  dbcs_cpu_core_count = var.dbcs_cpu_core_count
  dbcs_db_edition     = var.dbcs_db_edition
  dbcs_admin_password = var.dbcs_admin_password
  dbcs_db_name        = var.dbcs_db_name
  dbcs_db_version     = var.dbcs_db_version
  dbcs_storage_size_in_gb = var.dbcs_storage_size_in_gb
  dbcs_node_count     = var.dbcs_node_count
  dbcs_license_model  = var.dbcs_license_model
  ssh_public_key      = var.ssh_public_key

  freeform_tags = var.freeform_tags

  depends_on = [module.networking]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. ANALYTICS
# OAC Instance + Private Access Channel (PAC)
# PAC provisioning takes 15–40 minutes.
# ═══════════════════════════════════════════════════════════════════════════════

module "analytics" {
  source = "./modules/analytics"

  poc_compartment_ocid  = var.poc_compartment_ocid
  oac_display_name      = var.oac_display_name
  oac_capacity_type     = var.oac_capacity_type
  oac_capacity_value    = var.oac_capacity_value
  oac_feature_set       = var.oac_feature_set
  oac_license_type      = var.oac_license_type
  oac_idcs_access_token = var.oac_idcs_access_token

  poc_vcn_id        = module.networking.poc_vcn_id
  oac_pac_subnet_id = module.networking.oac_pac_subnet_id
  nsg_oac_pac_id    = module.networking.nsg_oac_pac_id
  region            = var.region

  freeform_tags = var.freeform_tags

  depends_on = [module.networking, module.database]
}
