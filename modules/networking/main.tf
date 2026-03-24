# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Networking Module                                                         ║
# ║  POC VCN + Dev VCN + LPG Peering + Security Lists + Route Tables + NSGs    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# POC VCN
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_vcn" "poc" {
  compartment_id = var.poc_compartment_ocid
  cidr_blocks    = [var.poc_vcn_cidr]
  display_name   = var.poc_vcn_display_name
  dns_label      = "pocvcn"
  freeform_tags  = var.freeform_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dev VCN
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_vcn" "dev" {
  compartment_id = var.dev_compartment_ocid
  cidr_blocks    = [var.dev_vcn_cidr]
  display_name   = var.dev_vcn_display_name
  dns_label      = "devvcn"
  freeform_tags  = var.freeform_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# LOCAL PEERING GATEWAYS
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_local_peering_gateway" "poc_to_dev" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "lpg-poc-to-dev"
  peer_id        = oci_core_local_peering_gateway.dev_to_poc.id
  freeform_tags  = var.freeform_tags
}

resource "oci_core_local_peering_gateway" "dev_to_poc" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "lpg-dev-to-poc"
  freeform_tags  = var.freeform_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# DHCP OPTIONS (VCN Default DNS Resolver — required for private endpoint FQDN)
# ═══════════════════════════════════════════════════════════════════════════════

resource "oci_core_dhcp_options" "poc_dhcp" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "dhcp-poc-private"
  freeform_tags  = var.freeform_tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["pocvcn.oraclevcn.com"]
  }
}

resource "oci_core_dhcp_options" "dev_dhcp" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "dhcp-dev-private"
  freeform_tags  = var.freeform_tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["devvcn.oraclevcn.com"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY LISTS — POC VCN
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
# SECURITY LISTS — Dev VCN
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
# NETWORK SECURITY GROUPS (granular per-VNIC control)
# ═══════════════════════════════════════════════════════════════════════════════

# ─── NSG: ADB-S Private Endpoint ─────────────────────────────────────────────

resource "oci_core_network_security_group" "adb_private" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "nsg-adb-private"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_network_security_group_security_rule" "adb_ingress_oac_listener" {
  network_security_group_id = oci_core_network_security_group.adb_private.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.oac_pac_subnet_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "OAC PAC to ADB-S listener"

  tcp_options {
    destination_port_range {
      min = var.adb_listener_port
      max = var.adb_listener_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "adb_ingress_oac_https" {
  network_security_group_id = oci_core_network_security_group.adb_private.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.oac_pac_subnet_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "OAC PAC to ADB-S HTTPS"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "adb_egress_dev_dbcs" {
  network_security_group_id = oci_core_network_security_group.adb_private.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = var.dev_db_subnet_cidr
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  description               = "ADB-S to Dev DBCS via LPG"

  tcp_options {
    destination_port_range {
      min = 1521
      max = 1521
    }
  }
}

# ─── NSG: OAC PAC ────────────────────────────────────────────────────────────

resource "oci_core_network_security_group" "oac_pac" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "nsg-oac-pac"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_network_security_group_security_rule" "oac_egress_adb_listener" {
  network_security_group_id = oci_core_network_security_group.oac_pac.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = var.adb_subnet_cidr
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  description               = "OAC PAC to ADB-S listener"

  tcp_options {
    destination_port_range {
      min = var.adb_listener_port
      max = var.adb_listener_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "oac_egress_adb_https" {
  network_security_group_id = oci_core_network_security_group.oac_pac.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = var.adb_subnet_cidr
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  description               = "OAC PAC to ADB-S HTTPS"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SERVICE GATEWAY — Dev VCN
# Provides access to OCI services (Object Storage, OS updates, etc.) without
# traversing the public internet.
# ═══════════════════════════════════════════════════════════════════════════════

data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  oci_services_id         = data.oci_core_services.all_oci_services.services[0].id
  oci_services_cidr_block = data.oci_core_services.all_oci_services.services[0].cidr_block
}

resource "oci_core_service_gateway" "dev" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "sgw-dev"
  freeform_tags  = var.freeform_tags

  services {
    service_id = local.oci_services_id
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTE TABLES
# ═══════════════════════════════════════════════════════════════════════════════

# ─── POC VCN: ADB-S Subnet Route Table ───────────────────────────────────────

resource "oci_core_route_table" "poc_adb" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-adb-private"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG"
  }
}

# ─── POC VCN: OAC PAC Subnet Route Table ─────────────────────────────────────

resource "oci_core_route_table" "poc_oac_pac" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-oac-pac"
  freeform_tags  = var.freeform_tags

  # Note: No default route (0.0.0.0/0) — POC VCN has no internet gateway.
  # Only intra-VCN traffic to ADB-S subnet is needed (implicit local route).
  # LPG route included for optional direct OAC→Dev DBCS connectivity (Section 11).

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG (optional OAC→Dev DBCS)"
  }
}

# ─── Dev VCN: DBCS Subnet Route Table ────────────────────────────────────────

resource "oci_core_route_table" "dev_db" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "rt-dev-private"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.poc_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.dev_to_poc.id
    description       = "Route to POC VCN via LPG"
  }

  route_rules {
    destination       = local.oci_services_cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.dev.id
    description       = "Route to OCI services via Service Gateway"
  }
}

# ─── POC VCN: Compute Subnet Route Table ────────────────────────────────────

resource "oci_core_route_table" "poc_compute" {
  compartment_id = var.poc_compartment_ocid
  vcn_id         = oci_core_vcn.poc.id
  display_name   = "rt-poc-compute"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.dev_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.poc_to_dev.id
    description       = "Route to Dev VCN via LPG"
  }
}

# ─── Dev VCN: Compute Subnet Route Table ───────────────────────────────────

resource "oci_core_route_table" "dev_compute" {
  compartment_id = var.dev_compartment_ocid
  vcn_id         = oci_core_vcn.dev.id
  display_name   = "rt-dev-compute"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = var.poc_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.dev_to_poc.id
    description       = "Route to POC VCN via LPG"
  }

  route_rules {
    destination       = local.oci_services_cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.dev.id
    description       = "Route to OCI services via Service Gateway"
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY LISTS — Compute
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

# ═══════════════════════════════════════════════════════════════════════════════
# SUBNETS
# ═══════════════════════════════════════════════════════════════════════════════

# ─── POC VCN: ADB-S Private Endpoint Subnet ──────────────────────────────────

resource "oci_core_subnet" "adb_private" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.adb_subnet_cidr
  display_name               = "private-adb-sub"
  dns_label                  = "adbsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_adb.id
  security_list_ids          = [oci_core_security_list.adb_private.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── POC VCN: OAC PAC Subnet ─────────────────────────────────────────────────

resource "oci_core_subnet" "oac_pac" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.oac_pac_subnet_cidr
  display_name               = "oac-pac-sub"
  dns_label                  = "oacpacsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_oac_pac.id
  security_list_ids          = [oci_core_security_list.oac_pac.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── POC VCN: Compute Subnet ────────────────────────────────────────────────

resource "oci_core_subnet" "poc_compute" {
  compartment_id             = var.poc_compartment_ocid
  vcn_id                     = oci_core_vcn.poc.id
  cidr_block                 = var.poc_compute_subnet_cidr
  display_name               = "poc-compute-sub"
  dns_label                  = "poccompsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.poc_compute.id
  security_list_ids          = [oci_core_security_list.poc_compute.id]
  dhcp_options_id            = oci_core_dhcp_options.poc_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── Dev VCN: Compute Subnet ───────────────────────────────────────────────

resource "oci_core_subnet" "dev_compute" {
  compartment_id             = var.dev_compartment_ocid
  vcn_id                     = oci_core_vcn.dev.id
  cidr_block                 = var.dev_compute_subnet_cidr
  display_name               = "dev-compute-sub"
  dns_label                  = "devcompsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.dev_compute.id
  security_list_ids          = [oci_core_security_list.dev_compute.id]
  dhcp_options_id            = oci_core_dhcp_options.dev_dhcp.id
  freeform_tags              = var.freeform_tags
}

# ─── Dev VCN: DBCS Subnet ────────────────────────────────────────────────────

resource "oci_core_subnet" "dev_db" {
  compartment_id             = var.dev_compartment_ocid
  vcn_id                     = oci_core_vcn.dev.id
  cidr_block                 = var.dev_db_subnet_cidr
  display_name               = "dev-db-sub"
  dns_label                  = "devdbsub"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.dev_db.id
  security_list_ids          = [oci_core_security_list.dev_db.id]
  dhcp_options_id            = oci_core_dhcp_options.dev_dhcp.id
  freeform_tags              = var.freeform_tags
}
