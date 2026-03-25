# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Cross-VCN Private DNS Resolution                                         ║
# ║                                                                           ║
# ║  POC VCN (pocvcn.oraclevcn.com) ←→ Dev VCN (devvcn.oraclevcn.com)        ║
# ║  Enables hostname resolution across VCNs via LPG using DNS forwarding.    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Resolver Associations (look up the auto-created VCN resolvers) ─────────

data "oci_core_vcn_dns_resolver_association" "poc" {
  vcn_id = oci_core_vcn.poc.id

  depends_on = [
    oci_core_subnet.poc_compute,
    oci_core_subnet.adb_private,
    oci_core_subnet.oac_pac,
  ]
}

data "oci_core_vcn_dns_resolver_association" "dev" {
  vcn_id = oci_core_vcn.dev.id

  depends_on = [
    oci_core_subnet.dev_compute,
    oci_core_subnet.dev_db,
  ]
}

# ─── POC VCN: Listening Endpoint ────────────────────────────────────────────
# Dev VCN forwards queries for pocvcn.oraclevcn.com to this endpoint.

resource "oci_dns_resolver_endpoint" "poc_listener" {
  resolver_id   = data.oci_core_vcn_dns_resolver_association.poc.dns_resolver_id
  name          = "poc_listener"
  is_forwarding = false
  is_listening  = true
  subnet_id     = oci_core_subnet.poc_compute.id
  scope         = "PRIVATE"
  endpoint_type = "VNIC"
}

# ─── POC VCN: Forwarding Endpoint ──────────────────────────────────────────
# Sends queries for devvcn.oraclevcn.com to Dev VCN's listening endpoint.

resource "oci_dns_resolver_endpoint" "poc_forwarder" {
  resolver_id   = data.oci_core_vcn_dns_resolver_association.poc.dns_resolver_id
  name          = "poc_forwarder"
  is_forwarding = true
  is_listening  = false
  subnet_id     = oci_core_subnet.poc_compute.id
  scope         = "PRIVATE"
  endpoint_type = "VNIC"
}

# ─── Dev VCN: Listening Endpoint ────────────────────────────────────────────
# POC VCN forwards queries for devvcn.oraclevcn.com to this endpoint.

resource "oci_dns_resolver_endpoint" "dev_listener" {
  resolver_id   = data.oci_core_vcn_dns_resolver_association.dev.dns_resolver_id
  name          = "dev_listener"
  is_forwarding = false
  is_listening  = true
  subnet_id     = oci_core_subnet.dev_compute.id
  scope         = "PRIVATE"
  endpoint_type = "VNIC"
}

# ─── Dev VCN: Forwarding Endpoint ──────────────────────────────────────────
# Sends queries for pocvcn.oraclevcn.com to POC VCN's listening endpoint.

resource "oci_dns_resolver_endpoint" "dev_forwarder" {
  resolver_id   = data.oci_core_vcn_dns_resolver_association.dev.dns_resolver_id
  name          = "dev_forwarder"
  is_forwarding = true
  is_listening  = false
  subnet_id     = oci_core_subnet.dev_compute.id
  scope         = "PRIVATE"
  endpoint_type = "VNIC"
}

# ─── POC VCN Resolver: Forward devvcn.oraclevcn.com → Dev Listener ─────────

resource "oci_dns_resolver" "poc" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.poc.dns_resolver_id
  scope       = "PRIVATE"

  rules {
    action                 = "FORWARD"
    destination_addresses  = [oci_dns_resolver_endpoint.dev_listener.listening_address]
    source_endpoint_name   = oci_dns_resolver_endpoint.poc_forwarder.name
    qname_cover_conditions = ["devvcn.oraclevcn.com"]
  }

  depends_on = [
    oci_dns_resolver_endpoint.poc_listener,
    oci_dns_resolver_endpoint.poc_forwarder,
    oci_dns_resolver_endpoint.dev_listener,
  ]
}

# ─── Dev VCN Resolver: Forward pocvcn.oraclevcn.com → POC Listener ─────────

resource "oci_dns_resolver" "dev" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.dev.dns_resolver_id
  scope       = "PRIVATE"

  rules {
    action                 = "FORWARD"
    destination_addresses  = [oci_dns_resolver_endpoint.poc_listener.listening_address]
    source_endpoint_name   = oci_dns_resolver_endpoint.dev_forwarder.name
    qname_cover_conditions = ["pocvcn.oraclevcn.com"]
  }

  depends_on = [
    oci_dns_resolver_endpoint.dev_listener,
    oci_dns_resolver_endpoint.dev_forwarder,
    oci_dns_resolver_endpoint.poc_listener,
  ]
}
