# OAC Private Endpoint ADB-S Connectivity — Terraform

Infrastructure-as-Code for deploying Oracle Analytics Cloud connected to a Private Endpoint Autonomous Database Serverless, with cross-VCN peering to a Dev DBCS instance.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  OAC Managed Infrastructure                                 │
│  ┌───────────────────────┐                                  │
│  │  Oracle Analytics     │                                  │
│  │  Cloud Instance       │                                  │
│  └──────────┬────────────┘                                  │
│             │ Private Access Channel                        │
└─────────────┼───────────────────────────────────────────────┘
              │
┌─────────────┼───────────────────────────────────────────────┐
│  POC VCN    │  10.0.0.0/16                                  │
│             ▼                                               │
│  ┌──────────────────────┐    ┌──────────────────────────┐   │
│  │  oac-pac-sub         │    │  private-adb-sub         │   │
│  │  10.0.2.0/24         │───▶│  10.0.1.0/24             │   │
│  │  (PAC VNIC)          │    │  (ADB-S Private Endpoint)│   │
│  │  sl-oac-pac          │    │  sl-adb-private          │   │
│  │  nsg-oac-pac         │    │  nsg-adb-private         │   │
│  └──────────────────────┘    └────────────┬─────────────┘   │
│                                           │                 │
│                              ┌────────────┴─────────────┐   │
│                              │  lpg-poc-to-dev           │   │
│                              └────────────┬─────────────┘   │
└───────────────────────────────────────────┼─────────────────┘
                                            │ LPG Peering
┌───────────────────────────────────────────┼─────────────────┐
│  Dev VCN   10.1.0.0/16                    │                 │
│                              ┌────────────┴─────────────┐   │
│                              │  lpg-dev-to-poc           │   │
│                              └────────────┬─────────────┘   │
│                                           │                 │
│  ┌────────────────────────────────────────┴─────────────┐   │
│  │  dev-db-sub                                          │   │
│  │  10.1.1.0/24                                         │   │
│  │  (Dev DBCS Instance)                                 │   │
│  │  sl-dev-db                                           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Traffic Flows

| Source | Destination | Port | Path | Purpose |
|--------|-------------|------|------|---------|
| OAC (PAC) | ADB-S PE | 1522 | Intra-VCN | Analytics queries (mTLS) |
| OAC (PAC) | ADB-S PE | 443 | Intra-VCN | REST API / HTTPS |
| ADB-S PE | Dev DBCS | 1521 | LPG | DB Link / data pipeline |
| OAC (PAC)* | Dev DBCS | 1521 | LPG | Direct analytics (optional) |

\* Optional — requires uncommenting DNS zone in analytics module.

## Project Structure

```
terraform-oac-adb-private/
├── provider.tf                    # OCI provider + version constraints
├── variables.tf                   # All configurable parameters
├── main.tf                        # Module composition + dependency ordering
├── outputs.tf                     # Consolidated outputs for validation
├── terraform.tfvars.example       # Template — copy to terraform.tfvars
├── .gitignore
├── README.md
└── modules/
    ├── iam/                       # IAM policies (OAC service + admin group + ADB-S)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/                 # VCNs, LPGs, subnets, security lists, NSGs, routes
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── database/                   # ADB-S (private endpoint) + Dev DBCS
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── analytics/                  # OAC instance + Private Access Channel
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

1. **OCI CLI configured** with API key or instance principal authentication
2. **Terraform >= 1.5.0** installed
3. **OCI Provider >= 5.30.0** (automatically fetched)
4. **IDCS Access Token** for OAC provisioning — generate via:
   ```bash
   # Using OCI CLI (preferred)
   oci iam region-idcs-endpoint get --region <region>
   # Then POST to the IDCS token endpoint with client credentials
   ```
5. **IAM Group** `AnalyticsAdmins` must exist (or set `analytics_admin_group_name`)
6. **SSH Key Pair** for DBCS node access
7. **Tenancy Limits** verified: minimum 2 VCNs, 1 LPG pair, 1 ADB-S, 1 DBCS, 1 OAC

## Quick Start

```bash
# 1. Clone and configure
cd terraform-oac-adb-private
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OCIDs, passwords, and IDCS token

# 2. Initialize
terraform init

# 3. Review plan
terraform plan -out=tfplan

# 4. Apply (expect 30–60 minutes for full deployment)
terraform apply tfplan
```

## Deployment Timeline

| Resource | Approximate Time |
|----------|-----------------|
| IAM Policies | < 1 minute |
| VCNs, Subnets, LPGs, Security Lists | 1–3 minutes |
| ADB-S (Private Endpoint) | 5–15 minutes |
| Dev DBCS | 20–40 minutes |
| OAC Instance | 15–30 minutes |
| OAC PAC | 15–40 minutes |
| **Total** | **30–60 minutes** |

## Post-Apply Validation

After `terraform apply` completes, verify the `validation_checklist` output:

```bash
terraform output validation_checklist
```

Expected:
```
{
  "1_lpg_peering"    = "PEERED"
  "2_adb_private_ep" = "xxxxxxxx.adb.us-ashburn-1.oraclecloudapps.com"
  "3_adb_private_ip" = "10.0.1.x"
  "4_pac_egress_ip"  = "10.0.2.x"
  "5_oac_url"        = "https://poc-oac-xxxxxxxx.analytics.ocp.oraclecloud.com"
}
```

Then complete the OAC connection setup:

1. Download the ADB-S wallet from the OCI Console
2. Verify `tnsnames.ora` references the private FQDN (not public)
3. In OAC Console → Create Connection → Oracle Autonomous Data Warehouse
4. Upload wallet, select service name, enter credentials
5. Test connection

## Wallet Download (CLI)

```bash
oci db autonomous-database generate-wallet \
  --autonomous-database-id $(terraform output -raw adb_id) \
  --password 'WalletP@ss1' \
  --file wallet_pocadb.zip
```

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| PAC creation fails silently | Missing `allow service analytics` policies | Verify IAM module applied first |
| Connection timeout in OAC | DNS zone missing on PAC | Check `private_source_dns_zones` in analytics module |
| Connection refused | ADB-S ACL missing OAC subnet | Verify `whitelisted_ips` includes `oac_pac_subnet_cidr` |
| ORA-12541: TNS no listener | Security list blocks port 1522 | Check sl-oac-pac egress + sl-adb-private ingress |
| ORA-28759: file open failure | Stale wallet | Re-download wallet after PE provisioning |

## Extending OAC to Dev DBCS (Optional)

To enable direct OAC → Dev DBCS connectivity across the LPG:

1. Uncomment the Dev VCN DNS zone block in `modules/analytics/main.tf`
2. The route table entry in `rt-poc-oac-pac` already includes the Dev VCN route
3. Add security list rules for TCP/1521 from `oac_pac_subnet_cidr` to `dev_db_subnet_cidr`
4. Run `terraform apply`

## Teardown

```bash
# Destroy in reverse order (Terraform handles dependencies)
terraform destroy
```

## Architecture Diagram
Picture goes here


**Warning:** ADB-S destruction is permanent. Ensure backups exist before destroying.

## References

- [OAC Private Access Channel documentation](https://docs.oracle.com/en-us/iaas/analytics-cloud/doc/manage-service-access-and-security.html)
- [ADB-S Private Endpoints](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adbsprivateaccess.htm)
- [OCI Local Peering Gateways](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/localVCNpeering.htm)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
