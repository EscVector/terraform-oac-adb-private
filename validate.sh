#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  validate.sh — Post-Apply Connectivity Validation                          ║
# ║  Maps to Section 10.1 of the OAC Private Endpoint ADB-S Reference Doc     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage: ./validate.sh
# Requires: OCI CLI configured, terraform state in current directory
#
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
PASS="${GREEN}PASS${NC}"
FAIL="${RED}FAIL${NC}"
WARN="${YELLOW}WARN${NC}"

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
  local num="$1" desc="$2" expected="$3" actual="$4"
  if [[ "$actual" == *"$expected"* ]]; then
    echo -e "  [${PASS}] #${num}: ${desc} — ${actual}"
    ((CHECKS_PASSED++))
  else
    echo -e "  [${FAIL}] #${num}: ${desc} — expected '${expected}', got '${actual}'"
    ((CHECKS_FAILED++))
  fi
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  OAC Private Endpoint ADB-S — Connectivity Validation      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Extract OCIDs from Terraform state ───────────────────────────────────────

echo "Extracting resource identifiers from Terraform state..."
echo ""

OAC_OCID=$(terraform output -raw oac_id 2>/dev/null || echo "MISSING")
ADB_OCID=$(terraform output -raw adb_id 2>/dev/null || echo "MISSING")
LPG_STATUS=$(terraform output -raw lpg_peering_status 2>/dev/null || echo "MISSING")
PAC_IP=$(terraform output -raw pac_ip_address 2>/dev/null || echo "MISSING")
ADB_PE=$(terraform output -raw adb_private_endpoint 2>/dev/null || echo "MISSING")
ADB_PE_IP=$(terraform output -raw adb_private_endpoint_ip 2>/dev/null || echo "MISSING")

# ─── Check 1: OAC PAC Status ─────────────────────────────────────────────────

if [[ "$OAC_OCID" != "MISSING" ]]; then
  OAC_STATE=$(oci analytics analytics-instance get \
    --analytics-instance-id "$OAC_OCID" \
    --query 'data."lifecycle-state"' --raw-output 2>/dev/null || echo "ERROR")
  check 1 "OAC instance lifecycle state" "ACTIVE" "$OAC_STATE"
else
  echo -e "  [${FAIL}] #1: OAC OCID not found in Terraform state"
  ((CHECKS_FAILED++))
fi

# ─── Check 2: ADB-S Status ───────────────────────────────────────────────────

if [[ "$ADB_OCID" != "MISSING" ]]; then
  ADB_STATE=$(oci db autonomous-database get \
    --autonomous-database-id "$ADB_OCID" \
    --query 'data."lifecycle-state"' --raw-output 2>/dev/null || echo "ERROR")
  check 2 "ADB-S lifecycle state" "AVAILABLE" "$ADB_STATE"
else
  echo -e "  [${FAIL}] #2: ADB-S OCID not found in Terraform state"
  ((CHECKS_FAILED++))
fi

# ─── Check 3: LPG Peering Status ─────────────────────────────────────────────

check 3 "LPG peering status" "PEERED" "$LPG_STATUS"

# ─── Check 4: ADB-S ACL includes OAC PAC subnet ──────────────────────────────

if [[ "$ADB_OCID" != "MISSING" ]]; then
  ACL_CHECK=$(oci db autonomous-database get \
    --autonomous-database-id "$ADB_OCID" \
    --query 'data."whitelisted-ips"' --raw-output 2>/dev/null || echo "ERROR")
  if [[ "$ACL_CHECK" == *"192.168.150.64"* ]]; then
    check 4 "ADB-S ACL includes OAC PAC subnet (192.168.150.64/26)" "192.168.150.64" "$ACL_CHECK"
  else
    echo -e "  [${FAIL}] #4: ADB-S ACL does NOT include 192.168.150.64/26 — got: ${ACL_CHECK}"
    ((CHECKS_FAILED++))
  fi
fi

# ─── Check 5: ADB-S Private Endpoint exists ──────────────────────────────────

if [[ "$ADB_PE" != "MISSING" && "$ADB_PE" != "" ]]; then
  check 5 "ADB-S private endpoint hostname" "adb." "$ADB_PE"
else
  echo -e "  [${FAIL}] #5: ADB-S private endpoint not configured"
  ((CHECKS_FAILED++))
fi

# ─── Check 6: ADB-S Private IP in correct subnet ─────────────────────────────

if [[ "$ADB_PE_IP" == 192.168.150.* ]]; then
  # ADB-S subnet is 192.168.150.0/26 (IPs .1 through .62)
  check 6 "ADB-S private IP in adb subnet (192.168.150.0/26)" "192.168.150." "$ADB_PE_IP"
else
  echo -e "  [${FAIL}] #6: ADB-S private IP '${ADB_PE_IP}' not in 192.168.150.0/26"
  ((CHECKS_FAILED++))
fi

# ─── Check 7: PAC egress IP in correct subnet ────────────────────────────────

if [[ "$PAC_IP" == 192.168.150.* ]]; then
  # PAC subnet is 192.168.150.64/26 (IPs .65 through .126)
  check 7 "PAC egress IP in oac-pac-sub (192.168.150.64/26)" "192.168.150." "$PAC_IP"
else
  echo -e "  [${FAIL}] #7: PAC IP '${PAC_IP}' not in 192.168.150.64/26"
  ((CHECKS_FAILED++))
fi

# ─── Check 8: PAC DNS zone configured ────────────────────────────────────────

if [[ "$OAC_OCID" != "MISSING" ]]; then
  PAC_DNS=$(oci analytics analytics-instance get \
    --analytics-instance-id "$OAC_OCID" \
    --query 'data."private-access-channels"' --raw-output 2>/dev/null || echo "ERROR")
  if [[ "$PAC_DNS" == *"adb."* ]]; then
    check 8 "PAC DNS zone includes ADB-S zone" "adb." "Present"
  else
    echo -e "  [${WARN}] #8: Could not verify PAC DNS zones via CLI — check OCI Console manually"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "  Results: ${GREEN}${CHECKS_PASSED} passed${NC}, ${RED}${CHECKS_FAILED} failed${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [[ "$CHECKS_FAILED" -eq 0 ]]; then
  echo -e "  ${GREEN}All checks passed.${NC} Proceed with OAC connection setup:"
  echo "    1. Download ADB-S wallet from OCI Console"
  echo "    2. Verify tnsnames.ora references private FQDN"
  echo "    3. OAC Console → Create Connection → Upload wallet"
  echo "    4. Test connection"
else
  echo -e "  ${RED}${CHECKS_FAILED} check(s) failed.${NC} Review errors above before"
  echo "  attempting OAC connection configuration."
fi

echo ""
exit $CHECKS_FAILED
