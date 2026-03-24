# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Compute Module                                                            ║
# ║  Basic compute instances in POC and Dev private subnets                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# SSH Key
# ═══════════════════════════════════════════════════════════════════════════════

resource "tls_private_key" "compute" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ═══════════════════════════════════════════════════════════════════════════════
# POC Compute Instance
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_instance" "poc" {
  compartment_id      = var.poc_compartment_ocid
  availability_domain = var.ad_name
  display_name        = "poc-compute"
  shape               = var.instance_shape
  freeform_tags       = var.freeform_tags

  shape_config {
    ocpus         = var.instance_shape_ocpus
    memory_in_gbs = var.instance_shape_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  create_vnic_details {
    subnet_id        = var.poc_compute_subnet_id
    assign_public_ip = false
    display_name     = "poc-compute-vnic"
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.compute.public_key_openssh
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dev Compute Instance
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_instance" "dev" {
  compartment_id      = var.dev_compartment_ocid
  availability_domain = var.ad_name
  display_name        = "dev-compute"
  shape               = var.instance_shape
  freeform_tags       = var.freeform_tags

  shape_config {
    ocpus         = var.instance_shape_ocpus
    memory_in_gbs = var.instance_shape_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  create_vnic_details {
    subnet_id        = var.dev_compute_subnet_id
    assign_public_ip = false
    display_name     = "dev-compute-vnic"
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.compute.public_key_openssh
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# OCI Bastion Service — POC Compute Subnet
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_bastion_bastion" "poc" {
  compartment_id               = var.poc_compartment_ocid
  bastion_type                 = "STANDARD"
  target_subnet_id             = var.poc_compute_subnet_id
  name                         = "poc-bastion"
  client_cidr_block_allow_list = var.bastion_client_cidr_allow_list
  max_session_ttl_in_seconds   = var.bastion_max_session_ttl
  freeform_tags                = var.freeform_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# LPG Connectivity Validation
# Validates network config: LPG peering, routes, and ICMP security rules.
# ═══════════════════════════════════════════════════════════════════════════════

resource "null_resource" "validate_connectivity" {
  depends_on = [oci_core_instance.poc, oci_core_instance.dev]

  triggers = {
    poc_id = oci_core_instance.poc.id
    dev_id = oci_core_instance.dev.id
  }

  provisioner "local-exec" {
    command = "C:\\app\\python311\\python.exe ${path.module}/../../scripts/validate_ping.py ${var.poc_vcn_id} ${var.dev_vcn_id} ${var.poc_compartment_ocid} ${var.dev_compartment_ocid}"
  }
}
