# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Network Security Groups (granular per-VNIC control)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

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

resource "oci_core_network_security_group_security_rule" "adb_ingress_bastion_https" {
  network_security_group_id = oci_core_network_security_group.adb_private.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.poc_compute_subnet_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Bastion/compute subnet to ADB-S HTTPS (Database Actions)"

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

resource "oci_core_network_security_group_security_rule" "adb_egress_dns" {
  network_security_group_id = oci_core_network_security_group.adb_private.id
  direction                 = "EGRESS"
  protocol                  = "17"
  destination               = "169.254.169.254/32"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  description               = "DNS queries to VCN resolver"

  udp_options {
    destination_port_range {
      min = 53
      max = 53
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
