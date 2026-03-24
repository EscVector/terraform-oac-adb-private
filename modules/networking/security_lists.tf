# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Security Lists — All VCNs                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# POC VCN
# ═══════════════════════════════════════════════════════════════════════════════

# ─── sl-oac-pac: OAC Private Access Channel Subnet ───────────────────────────

resource "oci_core_security_list" "oac_pac" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "sl-oac-pac"
  freeform_tags  = var.freeform_tags

  # Egress: OAC PAC → ADB-S (mTLS/TLS)
  egress_security_rules {
    destination = var.adb_subnet_cidr
    protocol    = "6" # TCP
    stateless   = false
    description = "OAC to ADB-S listener (mTLS/TLS)"

    tcp_options {
      min = var.adb_listener_port
      max = var.adb_listener_port
    }
  }

  # Egress: OAC PAC → ADB-S (HTTPS/REST)
  egress_security_rules {
    destination = var.adb_subnet_cidr
    protocol    = "6"
    stateless   = false
    description = "OAC to ADB-S HTTPS/REST"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress: Return traffic from ADB-S
  ingress_security_rules {
    source    = var.adb_subnet_cidr
    protocol  = "6"
    stateless = false
    description = "Return traffic from ADB-S subnet"
  }
}

# ─── sl-adb-private: ADB-S Private Endpoint Subnet ───────────────────────────

resource "oci_core_security_list" "adb_private" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "sl-adb-private"
  freeform_tags  = var.freeform_tags

  # Ingress: From OAC PAC (mTLS/TLS)
  ingress_security_rules {
    source    = var.oac_pac_subnet_cidr
    protocol  = "6"
    stateless = false
    description = "From OAC PAC - database listener"

    tcp_options {
      min = var.adb_listener_port
      max = var.adb_listener_port
    }
  }

  # Ingress: From OAC PAC (HTTPS)
  ingress_security_rules {
    source    = var.oac_pac_subnet_cidr
    protocol  = "6"
    stateless = false
    description = "From OAC PAC - HTTPS/REST"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress: From POC Compute subnet (Bastion port-forwarding to Database Actions)
  ingress_security_rules {
    source    = var.poc_compute_subnet_cidr
    protocol  = "6"
    stateless = false
    description = "From Bastion/compute subnet - HTTPS (Database Actions)"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Egress: ADB-S → Dev DBCS via LPG
  egress_security_rules {
    destination = var.dev_db_subnet_cidr
    protocol    = "6"
    stateless   = false
    description = "ADB-S to Dev DBCS via LPG"

    tcp_options {
      min = 1521
      max = 1521
    }
  }

  # Egress: Return traffic to OAC PAC
  egress_security_rules {
    destination = var.oac_pac_subnet_cidr
    protocol    = "6"
    stateless   = false
    description = "Return traffic to OAC PAC subnet"
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dev VCN
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_security_list" "dev_db" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "sl-dev-db"
  freeform_tags  = var.freeform_tags

  # Ingress: From ADB-S via LPG
  ingress_security_rules {
    source    = var.adb_subnet_cidr
    protocol  = "6"
    stateless = false
    description = "From ADB-S subnet via LPG - DB listener"

    tcp_options {
      min = 1521
      max = 1521
    }
  }

  # Ingress: SSH for DBCS administration (from POC VCN only)
  ingress_security_rules {
    source    = var.poc_vcn_cidr
    protocol  = "6"
    stateless = false
    description = "SSH from POC VCN for DBCS admin"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Egress: Return traffic to POC VCN
  egress_security_rules {
    destination = var.poc_vcn_cidr
    protocol    = "6"
    stateless   = false
    description = "Return traffic to POC VCN via LPG"
  }

  # Egress: OCI services via Service Gateway
  egress_security_rules {
    destination      = local.oci_services_cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    description      = "HTTPS to OCI services via Service Gateway"

    tcp_options {
      min = 443
      max = 443
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Compute Subnets
# ═══════════════════════════════════════════════════════════════════════════════

# ─── sl-poc-compute: POC Compute Subnet ─────────────────────────────────────

resource "oci_core_security_list" "poc_compute" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "sl-poc-compute"
  freeform_tags  = var.freeform_tags

  # Ingress: SSH from Dev VCN
  ingress_security_rules {
    source    = var.dev_vcn_cidr
    protocol  = "6"
    stateless = false
    description = "SSH from Dev VCN via LPG"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: SSH within POC VCN
  ingress_security_rules {
    source    = var.poc_vcn_cidr
    protocol  = "6"
    stateless = false
    description = "SSH within POC VCN"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: ICMP from Dev VCN (ping/traceroute)
  ingress_security_rules {
    source    = var.dev_vcn_cidr
    protocol  = "1"
    stateless = false
    description = "ICMP from Dev VCN via LPG"
  }

  # Ingress: ICMP within POC VCN
  ingress_security_rules {
    source    = var.poc_vcn_cidr
    protocol  = "1"
    stateless = false
    description = "ICMP within POC VCN"
  }

  # Egress: All to Dev VCN via LPG
  egress_security_rules {
    destination = var.dev_vcn_cidr
    protocol    = "all"
    stateless   = false
    description = "All traffic to Dev VCN via LPG"
  }

  # Egress: All within POC VCN
  egress_security_rules {
    destination = var.poc_vcn_cidr
    protocol    = "all"
    stateless   = false
    description = "All traffic within POC VCN"
  }
}

# ─── sl-dev-compute: Dev Compute Subnet ─────────────────────────────────────

resource "oci_core_security_list" "dev_compute" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "sl-dev-compute"
  freeform_tags  = var.freeform_tags

  # Ingress: SSH from POC VCN
  ingress_security_rules {
    source    = var.poc_vcn_cidr
    protocol  = "6"
    stateless = false
    description = "SSH from POC VCN via LPG"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: SSH within Dev VCN
  ingress_security_rules {
    source    = var.dev_vcn_cidr
    protocol  = "6"
    stateless = false
    description = "SSH within Dev VCN"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: ICMP from POC VCN (ping/traceroute)
  ingress_security_rules {
    source    = var.poc_vcn_cidr
    protocol  = "1"
    stateless = false
    description = "ICMP from POC VCN via LPG"
  }

  # Ingress: ICMP within Dev VCN
  ingress_security_rules {
    source    = var.dev_vcn_cidr
    protocol  = "1"
    stateless = false
    description = "ICMP within Dev VCN"
  }

  # Egress: All to POC VCN via LPG
  egress_security_rules {
    destination = var.poc_vcn_cidr
    protocol    = "all"
    stateless   = false
    description = "All traffic to POC VCN via LPG"
  }

  # Egress: All within Dev VCN
  egress_security_rules {
    destination = var.dev_vcn_cidr
    protocol    = "all"
    stateless   = false
    description = "All traffic within Dev VCN"
  }

  # Egress: OCI services via Service Gateway
  egress_security_rules {
    destination      = local.oci_services_cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
    description      = "HTTPS to OCI services via Service Gateway"

    tcp_options {
      min = 443
      max = 443
    }
  }
}
