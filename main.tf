# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  OAC Private Endpoint ADB-S Connectivity — Root Module                     ║
# ║                                                                            ║
# ║  Topology: OAC PAC → POC VCN (ADB-S PE) ←→ LPG ←→ Dev VCN (DBCS)         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 1. IAM POLICIES
# Must be created before networking/compute to avoid authorization failures.
# ═══════════════════════════════════════════════════════════════════════════════

module "iam" {
  source = "./modules/iam"

  tenancy_ocid         = var.tenancy_ocid
  poc_compartment_ocid = var.poc_compartment_ocid
  dev_compartment_ocid = var.dev_compartment_ocid
  admin_group_name     = var.admin_group_name
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

  poc_compute_subnet_cidr = var.poc_compute_subnet_cidr
  dev_compute_subnet_cidr = var.dev_compute_subnet_cidr

  adb_listener_port = local.adb_listener_port
  freeform_tags     = var.freeform_tags

  depends_on = [module.iam]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. COMPUTE
# Basic instances in POC and Dev private compute subnets
# ═══════════════════════════════════════════════════════════════════════════════

module "compute" {
  source = "./modules/compute"

  poc_compartment_ocid = var.poc_compartment_ocid
  dev_compartment_ocid = var.dev_compartment_ocid
  ad_name              = local.ad_name

  poc_vcn_id            = module.networking.poc_vcn_id
  dev_vcn_id            = module.networking.dev_vcn_id
  poc_compute_subnet_id = module.networking.poc_compute_subnet_id
  dev_compute_subnet_id = module.networking.dev_compute_subnet_id

  instance_shape              = var.instance_shape
  instance_shape_ocpus        = var.instance_shape_ocpus
  instance_shape_memory_in_gbs = var.instance_shape_memory_in_gbs
  instance_image_ocid         = var.instance_image_ocid

  bastion_client_cidr_allow_list = var.bastion_client_cidr_allow_list
  bastion_max_session_ttl        = var.bastion_max_session_ttl

  freeform_tags = var.freeform_tags

  depends_on = [module.networking]
}

/* 
*/