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

  metadata = {
    ssh_authorized_keys = tls_private_key.compute.public_key_openssh
  }
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
