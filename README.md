# OAC Private Endpoint ADB-S Connectivity — Terraform

Infrastructure-as-Code for OCI dual-VCN topology with LPG peering, compute instances, and automated connectivity validation.

## Architecture

```mermaid
graph TB
    subgraph OCI["OCI Tenancy — us-ashburn-1"]
        direction TB

        subgraph POC_COMP["POC Compartment"]
            subgraph POC_VCN["POC VCN — 192.168.0.0/24"]
                direction TB

                subgraph OAC_SUB["oac-pac-sub  192.168.0.64/26"]
                    OAC["OAC Private<br/>Access Channel"]
                end

                subgraph ADB_SUB["private-adb-sub  192.168.0.0/26"]
                    ADB["ADB-S Private<br/>Endpoint"]
                end

                subgraph POC_COMP_SUB["poc-compute-sub  192.168.0.128/26"]
                    POC_VM["poc-compute<br/>VM.Standard.E5.Flex<br/>1 OCPU · 16 GB"]
                end

                LPG_POC(["lpg-poc-to-dev"])
            end
        end

        subgraph DEV_COMP["Dev Compartment"]
            subgraph DEV_VCN["Dev VCN — 192.168.1.0/24"]
                direction TB

                LPG_DEV(["lpg-dev-to-poc"])

                subgraph DEV_DB_SUB["dev-db-sub  192.168.1.0/26"]
                    DBCS["Dev DBCS<br/>Instance"]
                end

                subgraph DEV_COMP_SUB["dev-compute-sub  192.168.1.64/26"]
                    DEV_VM["dev-compute<br/>VM.Standard.E5.Flex<br/>1 OCPU · 16 GB"]
                end
            end
        end
    end

    OAC -->|"TCP 1522 mTLS / 443 HTTPS"| ADB
    ADB -->|"TCP 1521 DB Link"| LPG_POC
    POC_VM <-->|"SSH 22 · ICMP"| LPG_POC
    LPG_POC ====>|"LPG Peering"| LPG_DEV
    LPG_DEV -->|"TCP 1521"| DBCS
    LPG_DEV <-->|"SSH 22 · ICMP"| DEV_VM

    classDef vcnStyle fill:#1a1a2e,stroke:#4A4580,stroke-width:2px,color:#fff
    classDef subnetStyle fill:#16213e,stroke:#0F3460,stroke-width:1px,color:#ccc
    classDef resourceStyle fill:#0F3460,stroke:#E94560,stroke-width:1px,color:#fff
    classDef lpgStyle fill:#F97316,stroke:#EA580C,stroke-width:2px,color:#fff
    classDef compartmentStyle fill:#0d1117,stroke:#30363d,stroke-width:2px,color:#ccc

    class POC_VCN,DEV_VCN vcnStyle
    class OAC_SUB,ADB_SUB,POC_COMP_SUB,DEV_DB_SUB,DEV_COMP_SUB subnetStyle
    class OAC,ADB,POC_VM,DBCS,DEV_VM resourceStyle
    class LPG_POC,LPG_DEV lpgStyle
    class POC_COMP,DEV_COMP compartmentStyle
```

### Network Topology

```
 ┌─────────────────────────────────────────────────────────────────────┐
 │  POC Compartment                                                    │
 │  ┌───────────────────────────────────────────────────────────────┐  │
 │  │  POC VCN  192.168.0.0/24                                      │  │
 │  │                                                               │  │
 │  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐   │  │
 │  │  │ oac-pac-sub     │  │ private-adb-sub │  │ poc-compute  │   │  │
 │  │  │ .64/26          │─▶│ .0/26           │  │ -sub .128/26 │   │  │
 │  │  │ OAC PAC         │  │ ADB-S PE        │  │ poc-compute  │   │  │
 │  │  │ sl-oac-pac      │  │ sl-adb-private  │  │ sl-poc-comp  │   │  │
 │  │  │ nsg-oac-pac     │  │ nsg-adb-private │  │              │   │  │
 │  │  └─────────────────┘  └────────┬────────┘  └──────┬───────┘   │  │
 │  │                                │                   │          │  │
 │  │                       ┌────────┴───────────────────┴───────┐  │  │
 │  │                       │       lpg-poc-to-dev               │  │  │
 │  │                       └────────────────┬───────────────────┘  │  │
 │  └────────────────────────────────────────┼──────────────────────┘  │
 └───────────────────────────────────────────┼─────────────────────────┘
                                             │ LPG Peering (PEERED)
 ┌───────────────────────────────────────────┼─────────────────────────┐
 │  Dev Compartment                          │                         │
 │  ┌────────────────────────────────────────┼──────────────────────┐  │
 │  │  Dev VCN  192.168.1.0/24             │                        │  │
 │  │                       ┌────────────────┴───────────────────┐  │  │
 │  │                       │       lpg-dev-to-poc               │  │  │
 │  │                       └────────┬───────────────────┬───────┘  │  │
 │  │                                │                   │          │  │
 │  │  ┌─────────────────────────────┴──┐  ┌─────────────┴───────┐  │  │
 │  │  │ dev-db-sub                     │  │ dev-compute-sub     │  │  │
 │  │  │ 192.168.1.0/26              │  │ 192.168.1.64/26        │  │  │
 │  │  │ Dev DBCS                       │  │ dev-compute         │  │  │
 │  │  │ sl-dev-db                      │  │ sl-dev-compute      │  │  │
 │  │  └────────────────────────────────┘  └─────────────────────┘  │  │
 │  └───────────────────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────────────────┘
```

## Traffic Flows

| Source | Destination | Protocol / Port | Path | Purpose |
|--------|-------------|-----------------|------|---------|
| OAC (PAC) | ADB-S PE | TCP 1522 | Intra-VCN | Analytics queries (mTLS) |
| OAC (PAC) | ADB-S PE | TCP 443 | Intra-VCN | REST API / HTTPS |
| ADB-S PE | Dev DBCS | TCP 1521 | LPG | DB Link / data pipeline |
| poc-compute | dev-compute | ICMP / SSH 22 | LPG | Cross-VCN connectivity validation |
| dev-compute | poc-compute | ICMP / SSH 22 | LPG | Cross-VCN connectivity validation |

## Security Controls

| Security List | Subnet | Ingress | Egress |
|---------------|--------|---------|--------|
| sl-oac-pac | oac-pac-sub | ADB return traffic | TCP 1522/443 → ADB subnet |
| sl-adb-private | private-adb-sub | TCP 1522/443 from OAC PAC | TCP 1521 → Dev DBCS, return to OAC |
| sl-dev-db | dev-db-sub | TCP 1521 from ADB-S, SSH from POC | Return to POC VCN |
| sl-poc-compute | poc-compute-sub | SSH + ICMP from both VCNs | All to both VCNs |
| sl-dev-compute | dev-compute-sub | SSH + ICMP from both VCNs | All to both VCNs |

NSGs provide additional per-VNIC control: **nsg-adb-private** (ADB-S endpoint) and **nsg-oac-pac** (OAC PAC).

## Project Structure

```
terraform-oac-adb-private/
├── provider.tf                    # OCI provider + version constraints
├── variables.tf                   # All configurable parameters
├── main.tf                        # Module composition + dependency ordering
├── outputs.tf                     # Consolidated outputs
├── terraform.tfvars               # Environment-specific OCIDs
├── .gitignore
├── README.md
├── docs/
│   └── architecture.mmd           # Mermaid source (standalone)
├── scripts/
│   └── validate_ping.py           # LPG connectivity validator (OCI SDK)
└── modules/
    ├── iam/                       # IAM policies for networking + compute
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/                 # VCNs, LPGs, subnets, security lists, NSGs, routes
    │   ├── vcns.tf                # VCN definitions (POC + Dev)
    │   ├── lpg.tf                 # Local Peering Gateways
    │   ├── dhcp.tf                # DHCP options
    │   ├── security_lists.tf      # Security lists (all VCNs)
    │   ├── nsgs.tf                # Network Security Groups + rules
    │   ├── service_gateway.tf     # Service Gateway (Dev VCN)
    │   ├── route_tables.tf        # Route tables (all VCNs)
    │   ├── subnets.tf             # Subnet definitions (all VCNs)
    │   ├── variables.tf
    │   └── outputs.tf
    └── compute/                   # Compute instances + SSH key + LPG validation
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

1. **OCI CLI configured** with API key or instance principal authentication
2. **Terraform >= 1.5.0** installed
3. **OCI Provider >= 5.30.0** (automatically fetched)
4. **Python 3 + OCI SDK** for connectivity validation (`pip install oci`)
5. **Tenancy Limits**: minimum 2 VCNs, 1 LPG pair, 2 compute instances

## Quick Start

### 1. Compartment Requirements

This project deploys resources across **two separate OCI compartments**. Both must exist before running Terraform.

| Compartment | Variable | Resources Deployed |
|-------------|----------|--------------------|
| **POC** | `poc_compartment_ocid` | POC VCN, OAC Private Access Channel subnet, ADB-S private endpoint subnet, POC compute instance |
| **Dev** | `dev_compartment_ocid` | Dev VCN, Dev DBCS subnet, Dev compute instance |

The deploying user (or group specified by `admin_group_name`) must have the following permissions:

- **POC Compartment** — `manage virtual-network-family`, `manage instance-family`, `manage volume-family`
- **Dev Compartment** — `manage virtual-network-family`, `manage instance-family`, `manage volume-family`
- **Tenancy** — `inspect compartments`, `read app-catalog-listing`, `read instance-images`, `read instance-family`, `use volume-family`

> Terraform creates these IAM policies automatically via the `iam` module. The user running `terraform apply` must have permission to create policies at the tenancy level.

### 2. Configure Variables

```bash
cd terraform-oac-adb-private
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your environment-specific values:

```hcl
# Required
tenancy_ocid         = "ocid1.tenancy.oc1..aaaa..."
user_ocid            = "ocid1.user.oc1..aaaa..."
fingerprint          = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
private_key_path     = "~/.oci/oci_api_key.pem"
region               = "us-ashburn-1"

poc_compartment_ocid = "ocid1.compartment.oc1..aaaa..."
dev_compartment_ocid = "ocid1.compartment.oc1..aaaa..."
instance_image_ocid  = "ocid1.image.oc1.iad.aaaa..."
```

### 3. Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Connecting via the Bastion

Both compute instances are on private subnets with no public IP. An OCI Bastion is deployed in the POC compute subnet to provide SSH access.

### Automated (recommended)

The `bastion_connect.py` script creates a port-forwarding session and prints the SSH commands:

```bash
# POC instance
python scripts/bastion_connect.py

# Dev instance (hop through POC via LPG)
python scripts/bastion_connect.py --target dev
```

The script extracts SSH keys from Terraform state automatically if they don't exist.

### Manual

#### 1. Extract the SSH keys

```bash
# Private key (for SSH client)
terraform output -raw ssh_private_key_pem > compute.pem
chmod 600 compute.pem

# Public key (required by the bastion session)
terraform output -raw ssh_public_key_openssh > compute_pub.key
```

#### 2. Create a port-forwarding session

The bastion uses port forwarding to tunnel SSH traffic — no Bastion plugin required on the target instance.

```bash
oci bastion session create-port-forwarding \
  --bastion-id $(terraform output -raw bastion_id) \
  --ssh-public-key-file compute_pub.key \
  --target-private-ip $(terraform output -raw poc_instance_private_ip) \
  --target-port 22 \
  --session-ttl 3600 \
  --wait-for-state SUCCEEDED
```

#### 3. Open the tunnel

In a separate terminal, start the SSH tunnel using the session OCID from the output:

```bash
ssh -i compute.pem -N -L 2222:<poc-private-ip>:22 \
  -p 22 <session-ocid>@host.bastion.<region>.oci.oraclecloud.com
```

#### 4. Connect through the tunnel

In another terminal:

```bash
ssh -i compute.pem -p 2222 opc@localhost
```

#### 5. Hop to the Dev instance

From the POC instance, SSH across the LPG to the Dev compute instance. You must first copy the private key onto the POC host since there is no direct bastion path to the Dev VCN:

```bash
# From your local machine, copy the key through the tunnel
scp -i compute.pem -P 2222 compute.pem opc@localhost:~/.ssh/compute.pem

# Then on the POC instance
chmod 600 ~/.ssh/compute.pem
ssh -i ~/.ssh/compute.pem opc@<dev-private-ip>
```

> **Note:** The bastion is in the POC VCN and can reach POC instances directly. To access the Dev VCN (`192.168.1.0/24`), hop through the POC instance via the LPG peering.

> **Tip:** Restrict `bastion_client_cidr_allow_list` in `terraform.tfvars` to your public IP (e.g. `["203.0.113.5/32"]`) instead of the default `0.0.0.0/0`.

### MobaXterm (Windows)

#### 1. Create the bastion session

Create a port-forwarding session using the OCI CLI or the `bastion_connect.py` script as described above. Note the **session OCID** from the output.

#### 2. Set up the tunnel in MobaXterm

1. Open **Tools > MobaSSHTunnel (Port Forwarding)**.
2. Click **New SSH tunnel**.
3. Select **Local port forwarding**.
4. Configure the tunnel:

   | Field | Value |
   |-------|-------|
   | **Forwarded port** (local) | `2222` |
   | **SSH server** | `host.bastion.<region>.oci.oraclecloud.com` |
   | **SSH login** | `<session-ocid>` (the full `ocid1.bastionsession.oc1...` string) |
   | **SSH port** | `22` |
   | **Remote server** | Private IP of the target instance (e.g. `192.168.0.x`) |
   | **Remote port** | `22` |

5. Click the **key icon** and select `compute.pem` (the private key).
6. Click **Save**, then click **Play** to start the tunnel.

#### 3. Connect through the tunnel

1. Open a new **SSH session** in MobaXterm.
2. Set **Remote host** to `localhost`, **Port** to `2222`.
3. Set **Username** to `opc`.
4. Under **Advanced SSH settings**, check **Use private key** and select `compute.pem`.
5. Click **OK** to connect to the POC instance.

#### 4. Hop to the Dev instance

Copy the private key to the POC host, then SSH to Dev:

1. In MobaXterm, use the left-side SFTP panel to upload `compute.pem` to `/home/opc/.ssh/compute.pem` on the POC instance.
2. In the terminal session, run:

```bash
chmod 600 ~/.ssh/compute.pem
ssh -i ~/.ssh/compute.pem opc@<dev-private-ip>
```

> **Important:** You must copy the private key onto the POC compute host to SSH to the Dev instance. The bastion cannot reach the Dev VCN directly — the connection must hop through the POC instance via the LPG peering.

### Accessing ADB-S Database Actions via the Bastion

The ADB-S private endpoint exposes Database Actions (SQL Developer Web) over HTTPS (port 443). You can tunnel to it through the bastion using port forwarding — no compute instance or Bastion plugin required.

#### 1. Get the ADB private endpoint IP and URL

```cmd
oci db autonomous-database get ^
  --autonomous-database-id <adb-ocid> ^
  --query "data.{ip:\"private-endpoint-ip\", url:\"private-endpoint\"}" ^
  --output table
```

To list all ADBs in the POC compartment:

```cmd
for /f "tokens=*" %i in ('terraform output -raw poc_compartment_id') do ^
  oci db autonomous-database list ^
    --compartment-id %i ^
    --query "data[].{name:\"display-name\", ip:\"private-endpoint-ip\", url:\"private-endpoint\"}" ^
    --output table
```

Note the **private endpoint IP** (e.g. `192.168.0.18`) and the **private endpoint URL** (e.g. `kww3pqa7.adb.us-ashburn-1.oraclecloud.com`).

#### 2. Create a port-forwarding session

```cmd
for /f "tokens=*" %i in ('terraform output -raw bastion_id') do ^
  oci bastion session create-port-forwarding ^
    --bastion-id %i ^
    --ssh-public-key-file compute_pub.key ^
    --target-private-ip <adb-private-endpoint-ip> ^
    --target-port 443 ^
    --session-ttl 3600 ^
    --wait-for-state SUCCEEDED
```

Copy the **session OCID** (`ocid1.bastionsession.oc1.iad...`) from the output — you will need the exact value for the tunnel command.

#### 3. Open the tunnel

In a **separate terminal**:

```cmd
ssh -i compute.pem -N -L 8443:<adb-private-endpoint-ip>:443 -p 22 <session-ocid>@host.bastion.us-ashburn-1.oci.oraclecloud.com
```

The terminal will appear to hang with no output — this is normal. The tunnel is active as long as this window stays open.

> **Important:** The `<session-ocid>` is the SSH username. It must be the full OCID exactly as shown in the session output. An incorrect session OCID will cause the connection to hang or refuse.

#### 4. Access Database Actions

Open your browser and navigate to:

```
https://localhost:8443/ords/sql-developer
```

Your browser will show a certificate warning because the ADB certificate is issued for `*.adb.us-ashburn-1.oraclecloud.com`, not `localhost`. You can safely proceed past the warning.

#### Certificate warning workaround (optional)

To avoid the certificate warning, add a hosts file entry so the ADB hostname resolves to localhost, and tunnel on port 443 instead of 8443.

**Windows** — edit `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```
127.0.0.1  <adb-hostname>.adb.us-ashburn-1.oraclecloud.com
```

**Linux/macOS** — edit `/etc/hosts`:

```
127.0.0.1  <adb-hostname>.adb.us-ashburn-1.oraclecloud.com
```

Then tunnel on port 443:

```cmd
ssh -i compute.pem -N -L 443:<adb-private-endpoint-ip>:443 -p 22 <session-ocid>@host.bastion.us-ashburn-1.oci.oraclecloud.com
```

And browse to:

```
https://<adb-hostname>.adb.us-ashburn-1.oraclecloud.com/ords/sql-developer
```

#### MobaXterm

Use the MobaSSHTunnel setup described in the compute section above, with these values:

| Field | Value |
|-------|-------|
| **Forwarded port** (local) | `8443` |
| **SSH server** | `host.bastion.us-ashburn-1.oci.oraclecloud.com` |
| **SSH login** | `<session-ocid>` (full `ocid1.bastionsession.oc1.iad...` string) |
| **SSH port** | `22` |
| **Remote server** | ADB private endpoint IP (e.g. `192.168.0.18`) |
| **Remote port** | `443` |

Then open `https://localhost:8443/ords/sql-developer` in your browser.

> **Note:** The bastion must be in the same VCN as the ADB private endpoint (POC VCN). Both the security list (`sl-adb-private`) and NSG (`nsg-adb-private`) must allow TCP 443 from the bastion's subnet (`poc-compute-sub`).

## Connectivity Validation

After `terraform apply`, the compute module automatically runs `validate_ping.py` which checks:

1. **LPG Peering Status** — confirms `PEERED` state
2. **POC Compute Routes** — verifies route to Dev VCN via LPG
3. **Dev Compute Routes** — verifies route to POC VCN via LPG
4. **ICMP Security Rules** — confirms bidirectional ICMP ingress/egress

```
[1/4] Checking LPG peering status...
  lpg-poc-to-dev: peering_status=PEERED
  PASS - LPG is PEERED
[2/4] Checking POC compute subnet routes...
  Route to Dev VCN (192.168.1.0/24): PASS
[3/4] Checking Dev compute subnet routes...
  Route to POC VCN (192.168.0.0/24): PASS
[4/4] Checking ICMP rules in security lists...
  POC (sl-poc-compute): ICMP ingress=PASS, egress=PASS
  Dev (sl-dev-compute): ICMP ingress=PASS, egress=PASS

============================================================
RESULT: All network connectivity checks PASSED
```

## Teardown

```bash
terraform destroy
```

## Why a Local Peering Gateway?

This project uses an LPG rather than a Dynamic Routing Gateway (DRG) or a single flat VCN to intentionally limit connectivity options and reduce the attack surface.

### Security benefits

- **No internet exposure** — All traffic between peered VCNs stays on the OCI backbone. Packets never traverse the public internet, eliminating eavesdropping and man-in-the-middle risks.
- **Point-to-point blast radius** — An LPG connects exactly two VCNs. If one VCN is compromised, only its direct peer is reachable — not every VCN in the environment.
- **No transitive routing** — VCN-A peered with VCN-B, and VCN-B peered with VCN-C, does **not** allow VCN-A to reach VCN-C. A peered VCN also cannot use its peer's internet gateway, NAT gateway, or service gateway. This prevents unintended lateral movement.
- **Bilateral IAM consent** — Establishing a peering requires explicit IAM policy grants from both VCN administrators (requestor and acceptor). Unauthorized peering is not possible.
- **Granular route and security control** — Each side must independently add route rules pointing to the LPG and open security list / NSG rules. Without explicit rules on **both** sides, no traffic flows. A dedicated route table can be associated with the LPG itself for additional control.

### Architectural simplicity

- **Less misconfiguration risk** — A direct link between two VCNs has no central router, no hub-and-spoke import/export policies, and no chance of accidentally leaking routes between unrelated VCNs.
- **Lowest latency** — LPG traffic takes a direct path with no virtual-router hop, yielding lower latency than DRG-routed traffic.

### When to use a DRG instead

A DRG is the better choice when you need to connect three or more VCNs, require cross-region connectivity, or want centralized transit routing. The upgraded DRG supports up to 300 VCN attachments with flexible route import/export policies — but that flexibility comes with a larger blast radius and more complex route management.

| Consideration | LPG | DRG |
|---------------|-----|-----|
| VCN connectivity | Point-to-point (2 VCNs) | Up to 300 attachments |
| Region scope | Same region only | Same or cross-region |
| Transitive routing | Not possible | Configurable via DRG route tables |
| Latency | Lowest (direct path) | Slightly higher (virtual router hop) |
| Blast radius | Minimal | Broader — all attached VCNs share a routing domain |
| Best for | Strict isolation between VCN pairs | Hub-and-spoke, multi-region, or many-VCN topologies |

> **This project's topology** — an OAC private endpoint VCN peered with an ADB-S VCN — is a textbook LPG use case. The only permitted communication is between those two services, and the LPG ensures no other VCN can be inadvertently reached.

## References

- [OCI Local Peering Gateways](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/localVCNpeering.htm)
- [OAC Private Access Channel](https://docs.oracle.com/en-us/iaas/analytics-cloud/doc/manage-service-access-and-security.html)
- [ADB-S Private Endpoints](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adbsprivateaccess.htm)
- [Basic Routing Scenarios for the Enhanced DRG](https://www.ateam-oracle.com/basic-routing-scenarios-for-the-enhanced-drg)
- [Give an LPG Access to a Route Table](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/give-lpg-rt.htm)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
