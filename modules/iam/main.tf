# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  IAM Module                                                                ║
# ║  Policies for networking, compute, and supporting services                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# POC Compartment Policies
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_identity_policy" "poc_policies" {
  compartment_id = var.poc_compartment_ocid
  name           = "poc-infra-policies"
  description    = "Policies for POC compartment — networking and compute"

  statements = [
    "Allow group ${var.admin_group_name} to manage virtual-network-family in compartment id ${var.poc_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage instance-family in compartment id ${var.poc_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage volume-family in compartment id ${var.poc_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage bastion-family in compartment id ${var.poc_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage bastion-session in compartment id ${var.poc_compartment_ocid}",
  ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dev Compartment Policies
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_identity_policy" "dev_policies" {
  compartment_id = var.dev_compartment_ocid
  name           = "dev-infra-policies"
  description    = "Policies for Dev compartment — networking and compute"

  statements = [
    "Allow group ${var.admin_group_name} to manage virtual-network-family in compartment id ${var.dev_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage instance-family in compartment id ${var.dev_compartment_ocid}",
    "Allow group ${var.admin_group_name} to manage volume-family in compartment id ${var.dev_compartment_ocid}",
  ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Tenancy-level Policies (platform images, boot volumes)
# Requires tenancy admin — uncomment when tenancy-level access is available
# ═══════════════════════════════════════════════════════════════════════════════

# resource "oci_identity_policy" "tenancy_policies" {
#   compartment_id = var.tenancy_ocid
#   name           = "infra-tenancy-policies"
#   description    = "Tenancy-level policies for compute image access"
#
#   statements = [
#     "Allow group ${var.admin_group_name} to inspect compartments in tenancy",
#     "Allow group ${var.admin_group_name} to read app-catalog-listing in tenancy",
#     "Allow group ${var.admin_group_name} to read instance-images in tenancy",
#     "Allow group ${var.admin_group_name} to read instance-family in tenancy",
#     "Allow group ${var.admin_group_name} to use volume-family in tenancy",
#   ]
# }
