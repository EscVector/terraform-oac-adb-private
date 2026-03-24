# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  OAC Private Endpoint ADB-S Connectivity — Provider Configuration          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.30.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ─── Data Sources ─────────────────────────────────────────────────────────────

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  ad_name = data.oci_identity_availability_domains.ads.availability_domains[0].name

  # Port selection based on mTLS setting
  adb_listener_port = var.adb_is_mtls_required ? 1522 : 1521
}
