# OAC-ADB Dual-VCN Network Configuration — Manual Setup Guide

This document details every route table, security list, NSG, and DNS resolver rule required for the OAC Private Endpoint to ADB-S connectivity architecture with dual-VCN topology connected via Local Peering Gateway.

---

## Network Topology

```
POC VCN (192.168.0.0/24)                 Dev VCN (192.168.1.0/24)
  ├── private-adb-sub    192.168.0.0/26    ├── dev-db-sub       192.168.1.0/26
  ├── oac-pac-sub        192.168.0.64/26   ├── dev-compute-sub  192.168.1.64/26
  ├── poc-compute-sub    192.168.0.128/26  │
  │                                        │
  └── LPG (poc-to-dev) ◄──────────────────►└── LPG (dev-to-poc)
                                           └── Service Gateway (All OCI Services)
```

### Subnet-to-Resource Mapping

| Subnet | CIDR | VCN | Hosts |
|--------|------|-----|-------|
| private-adb-sub | 192.168.0.0/26 | POC | ADB-S Private Endpoint |
| oac-pac-sub | 192.168.0.64/26 | POC | OAC Private Access Channel |
| poc-compute-sub | 192.168.0.128/26 | POC | Compute, Bastion, DNS Resolver Endpoints |
| dev-db-sub | 192.168.1.0/26 | Dev | Oracle Base Database (DB System) |
| dev-compute-sub | 192.168.1.64/26 | Dev | Compute, DNS Resolver Endpoints |

### DHCP Options

Both VCNs use **Internet and VCN Resolver** (not Custom Resolver):

| VCN | DHCP Display Name | DNS Type | Search Domain |
|-----|-------------------|----------|---------------|
| POC | dhcp-poc-private | VcnLocalPlusInternet | pocvcn.oraclevcn.com |
| Dev | dhcp-dev-private | VcnLocalPlusInternet | devvcn.oraclevcn.com |

> **Critical**: If DHCP is set to "Custom Resolver", VCN private DNS and cross-VCN forwarding will not work.

---

## 1. Local Peering Gateways

Create one LPG in each VCN and peer them:

| LPG Name | VCN | Peer LPG |
|----------|-----|----------|
| lpg-poc-to-dev | POC | lpg-dev-to-poc |
| lpg-dev-to-poc | Dev | lpg-poc-to-dev |

After creation, establish the peering connection from one side. Status should show **PEERED**.

---

## 2. Route Tables

### rt-poc-adb-private (POC VCN — ADB Subnet)

Attached to: **private-adb-sub** (192.168.0.0/26)

| Destination | Type | Target | Description |
|-------------|------|--------|-------------|
| 192.168.1.0/24 | CIDR_BLOCK | lpg-poc-to-dev | Route to Dev VCN via LPG |

### rt-poc-oac-pac (POC VCN — OAC PAC Subnet)

Attached to: **oac-pac-sub** (192.168.0.64/26)

| Destination | Type | Target | Description |
|-------------|------|--------|-------------|
| 192.168.1.0/24 | CIDR_BLOCK | lpg-poc-to-dev | Route to Dev VCN via LPG (optional OAC-to-Dev DBCS) |

> No default route (0.0.0.0/0) — POC VCN has no internet gateway. Intra-VCN traffic to ADB-S uses the implicit local route.

### rt-poc-compute (POC VCN — Compute Subnet)

Attached to: **poc-compute-sub** (192.168.0.128/26)

| Destination | Type | Target | Description |
|-------------|------|--------|-------------|
| 192.168.1.0/24 | CIDR_BLOCK | lpg-poc-to-dev | Route to Dev VCN via LPG |

### rt-dev-private (Dev VCN — DB Subnet)

Attached to: **dev-db-sub** (192.168.1.0/26)

| Destination | Type | Target | Description |
|-------------|------|--------|-------------|
| 192.168.0.0/24 | CIDR_BLOCK | lpg-dev-to-poc | Route to POC VCN via LPG |
| All OCI Services | SERVICE_CIDR_BLOCK | Service Gateway | Route to OCI services (Object Storage, etc.) |

### rt-dev-compute (Dev VCN — Compute Subnet)

Attached to: **dev-compute-sub** (192.168.1.64/26)

| Destination | Type | Target | Description |
|-------------|------|--------|-------------|
| 192.168.0.0/24 | CIDR_BLOCK | lpg-dev-to-poc | Route to POC VCN via LPG |
| All OCI Services | SERVICE_CIDR_BLOCK | Service Gateway | Route to OCI services (Object Storage, etc.) |

---

## 3. Security Lists

### sl-oac-pac (POC VCN — OAC Private Access Channel Subnet)

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.0.0/26 | TCP | 1522 | OAC to ADB-S listener (mTLS) |
| 192.168.0.0/26 | TCP | 443 | OAC to ADB-S HTTPS/REST |

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.0.0/26 | TCP | All | Return traffic from ADB-S subnet |

### sl-adb-private (POC VCN — ADB-S Private Endpoint Subnet)

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.0.64/26 | TCP | 1522 | From OAC PAC — database listener (mTLS) |
| 192.168.0.64/26 | TCP | 443 | From OAC PAC — HTTPS/REST |
| 192.168.0.128/26 | TCP | 443 | From Bastion/compute — HTTPS (Database Actions) |

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.1.0/26 | TCP | 1521 | ADB-S to Dev DBCS via LPG |
| 192.168.0.64/26 | TCP | All | Return traffic to OAC PAC subnet |

### sl-dev-db (Dev VCN — Database Subnet)

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.0.0/26 | TCP | 1521 | From ADB-S subnet via LPG — DB listener |
| 192.168.0.0/24 | TCP | 22 | SSH from POC VCN for DBCS admin |

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.0.0/24 | TCP | All | Return traffic to POC VCN via LPG |
| All OCI Services | TCP | 443 | HTTPS to OCI services via Service Gateway |

### sl-poc-compute (POC VCN — Compute Subnet)

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.1.0/24 | TCP | 22 | SSH from Dev VCN via LPG |
| 192.168.0.0/24 | TCP | 22 | SSH within POC VCN |
| 192.168.1.0/24 | UDP | 53 | DNS from Dev VCN resolver via LPG |
| 192.168.1.0/24 | ICMP | All | ICMP from Dev VCN via LPG |
| 192.168.0.0/24 | ICMP | All | ICMP within POC VCN |

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.1.0/24 | All | All | All traffic to Dev VCN via LPG |
| 192.168.0.0/24 | All | All | All traffic within POC VCN |

### sl-dev-compute (Dev VCN — Compute Subnet)

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.0.0/24 | TCP | 22 | SSH from POC VCN via LPG |
| 192.168.1.0/24 | TCP | 22 | SSH within Dev VCN |
| 192.168.0.0/24 | UDP | 53 | DNS from POC VCN resolver via LPG |
| 192.168.0.0/24 | ICMP | All | ICMP from POC VCN via LPG |
| 192.168.1.0/24 | ICMP | All | ICMP within Dev VCN |

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.0.0/24 | All | All | All traffic to POC VCN via LPG |
| 192.168.1.0/24 | All | All | All traffic within Dev VCN |
| All OCI Services | TCP | 443 | HTTPS to OCI services via Service Gateway |

---

## 4. Network Security Groups (NSGs)

NSGs provide per-VNIC security in addition to security lists. **Both** must allow traffic independently.

### nsg-adb-private (POC VCN — attached to ADB-S Private Endpoint)

**Ingress Rules:**

| Source | Protocol | Port | Description |
|--------|----------|------|-------------|
| 192.168.0.64/26 | TCP | 1522 | OAC PAC to ADB-S listener (mTLS) |
| 192.168.0.64/26 | TCP | 443 | OAC PAC to ADB-S HTTPS |
| 192.168.0.128/26 | TCP | 443 | Bastion/compute to ADB-S HTTPS (Database Actions) |

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.1.0/26 | TCP | 1521 | ADB-S to Dev DBCS via LPG |
| 169.254.169.254/32 | UDP | 53 | DNS queries to VCN resolver |

> **Important**: The DNS egress rule (UDP/53 to 169.254.169.254/32) is required for ADB-S to resolve hostnames. Without it, `UTL_INADDR` and database links using hostnames will fail.

### nsg-oac-pac (POC VCN — attached to OAC Private Access Channel)

**Egress Rules:**

| Destination | Protocol | Port | Description |
|-------------|----------|------|-------------|
| 192.168.0.0/26 | TCP | 1522 | OAC PAC to ADB-S listener (mTLS) |
| 192.168.0.0/26 | TCP | 443 | OAC PAC to ADB-S HTTPS |

---

## 5. OAC Private Access Channel Configuration

The OAC Private Access Channel (PAC) provides private connectivity from Oracle Analytics Cloud to the ADB-S private endpoint.

### PAC Setup (OCI Console)

1. Navigate to **Analytics Cloud** > your OAC instance > **Private Access Channel**
2. Configure:

| Setting | Value |
|---------|-------|
| VCN | POC VCN (192.168.0.0/24) |
| Subnet | oac-pac-sub (192.168.0.64/26) |
| NSG | nsg-oac-pac |
| DNS Zone | pocvcn.oraclevcn.com |

### PAC Connectivity Chain

```
OAC Instance
  └── Private Access Channel (oac-pac-sub, 192.168.0.64/26)
        ├── NSG: nsg-oac-pac (egress TCP/1522, TCP/443 to 192.168.0.0/26)
        ├── Security List: sl-oac-pac (egress TCP/1522, TCP/443 to 192.168.0.0/26)
        └── Route Table: rt-poc-oac-pac (192.168.1.0/24 via LPG)
              └── ADB-S Private Endpoint (private-adb-sub, 192.168.0.0/26)
                    ├── NSG: nsg-adb-private (ingress TCP/1522, TCP/443 from 192.168.0.64/26)
                    └── Security List: sl-adb-private (ingress TCP/1522, TCP/443 from 192.168.0.64/26)
```

### ADB-S Connection from OAC

- **Port**: 1522 (mTLS always required)
- **Protocol**: TCPS
- **Connection**: Use the ADB private endpoint hostname from the ADB details page
- **Wallet**: Required for mTLS — download from ADB console

---

## 6. Cross-VCN DNS Resolution

Enables POC VCN hosts to resolve Dev VCN hostnames (and vice versa) across the LPG. Required for database links using hostnames instead of IP addresses.

### Prerequisites

- DHCP options must use **Internet and VCN Resolver** (not Custom Resolver)
- Security lists must allow **UDP/53** between VCNs (already included in sl-poc-compute and sl-dev-compute)
- LPG must be peered and routes in place

### DNS Resolver Endpoints

Create four endpoints — a listener and forwarder in each VCN:

| Endpoint Name | VCN | Subnet | Type | Purpose |
|---------------|-----|--------|------|---------|
| poc_listener | POC | poc-compute-sub | Listening | Receives forwarded queries from Dev VCN |
| poc_forwarder | POC | poc-compute-sub | Forwarding | Sends queries to Dev VCN listener |
| dev_listener | Dev | dev-compute-sub | Listening | Receives forwarded queries from POC VCN |
| dev_forwarder | Dev | dev-compute-sub | Forwarding | Sends queries to POC VCN listener |

**Console steps** (repeat for each VCN):
1. Navigate to **Networking** > **VCN** > select VCN > **DNS Resolver**
2. Click **Manage Endpoints**
3. Add a **Listening Endpoint**: name, subnet, scope = PRIVATE, type = VNIC
4. Add a **Forwarding Endpoint**: name, subnet, scope = PRIVATE, type = VNIC
5. Note the **listening IP address** assigned to each listener — needed for forwarding rules

### DNS Forwarding Rules

After creating endpoints, configure forwarding rules on each VCN's resolver:

**POC VCN Resolver — Forward Rule:**

| Field | Value |
|-------|-------|
| Action | FORWARD |
| Domain Match (qname) | devvcn.oraclevcn.com |
| Source Endpoint | poc_forwarder |
| Destination Address | *\<IP of dev_listener\>* |

**Dev VCN Resolver — Forward Rule:**

| Field | Value |
|-------|-------|
| Action | FORWARD |
| Domain Match (qname) | pocvcn.oraclevcn.com |
| Source Endpoint | dev_forwarder |
| Destination Address | *\<IP of poc_listener\>* |

**Console steps:**
1. Navigate to **Networking** > **VCN** > select VCN > **DNS Resolver**
2. Click **Manage Rules**
3. Add rule: Action = FORWARD, enter the domain, select source endpoint, enter destination listener IP

### DNS Resolution Flow

```
POC Compute instance queries: dev.devdbsub.devvcn.oraclevcn.com
  └── POC VCN Resolver
        └── Matches rule: *.devvcn.oraclevcn.com
              └── poc_forwarder (192.168.0.128/26) ──LPG──► dev_listener (192.168.1.64/26)
                    └── Dev VCN Resolver
                          └── Resolves: dev.devdbsub.devvcn.oraclevcn.com → 192.168.1.x
                                └── Returns IP to POC VCN
```

---

## 7. Service Gateway (Dev VCN)

Provides private access to OCI services (Object Storage, etc.) without internet access.

| Setting | Value |
|---------|-------|
| VCN | Dev VCN |
| Services | All Services In Oracle Services Network |

Route rules referencing the service gateway use destination type **SERVICE_CIDR_BLOCK** with the "All OCI Services" CIDR (automatically provided by OCI).

---

## 8. Connectivity Verification Checklist

After completing the setup, verify each layer:

- [ ] **LPG**: Peering status = PEERED
- [ ] **Routes**: Each subnet's route table has the correct LPG and/or Service Gateway rules
- [ ] **Security Lists**: Ingress and egress rules match the tables above for each subnet
- [ ] **NSGs**: Rules on nsg-adb-private and nsg-oac-pac match the tables above
- [ ] **DHCP**: Both VCNs use Internet and VCN Resolver (not Custom)
- [ ] **DNS Endpoints**: All four created (two per VCN) and in ACTIVE state
- [ ] **DNS Rules**: Forwarding rules configured on both VCN resolvers
- [ ] **ICMP**: `ping` from POC compute to Dev compute succeeds (cross-VCN)
- [ ] **SSH**: SSH from POC compute to Dev compute on port 22 succeeds
- [ ] **ADB HTTPS**: Bastion port-forward to ADB private IP on port 443 loads Database Actions
- [ ] **ADB Listener**: `tnsping` or SQL*Plus connect to ADB on port 1522 succeeds
- [ ] **DNS Resolution**: From POC compute: `nslookup dev.devdbsub.devvcn.oraclevcn.com` returns Dev DB IP
- [ ] **OAC-to-ADB**: OAC can connect to ADB-S via Private Access Channel on port 1522
