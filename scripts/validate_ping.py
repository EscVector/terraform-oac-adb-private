#!/usr/bin/env python3
"""
Validate cross-VCN LPG connectivity by checking:
1. LPG peering status
2. Route tables have cross-VCN routes
3. Security lists allow ICMP between compute subnets

Usage: python validate_ping.py <poc_vcn_id> <dev_vcn_id> <poc_compartment> <dev_compartment>
"""

import sys
import oci


def main():
    if len(sys.argv) != 5:
        print("Usage: python validate_ping.py <poc_vcn_id> <dev_vcn_id> <poc_comp> <dev_comp>")
        sys.exit(1)

    poc_vcn_id, dev_vcn_id, poc_compartment, dev_compartment = sys.argv[1:5]

    config = oci.config.from_file()
    net = oci.core.VirtualNetworkClient(config)

    all_pass = True

    # 1. Check LPG peering
    print("[1/4] Checking LPG peering status...")
    poc_lpgs = net.list_local_peering_gateways(poc_compartment, vcn_id=poc_vcn_id).data
    lpg_ok = False
    for lpg in poc_lpgs:
        print(f"  {lpg.display_name}: peering_status={lpg.peering_status}")
        if lpg.peering_status == "PEERED":
            lpg_ok = True
    if lpg_ok:
        print("  PASS - LPG is PEERED")
    else:
        print("  FAIL - No PEERED LPG found")
        all_pass = False

    # 2. Check POC compute subnet routes
    print("[2/4] Checking POC compute subnet routes...")
    poc_subnets = net.list_subnets(poc_compartment, vcn_id=poc_vcn_id).data
    poc_compute_sub = next((s for s in poc_subnets if "compute" in s.display_name.lower()), None)
    if poc_compute_sub:
        rt = net.get_route_table(poc_compute_sub.route_table_id).data
        dev_vcn_cidr = net.get_vcn(dev_vcn_id).data.cidr_blocks[0]
        has_lpg_route = any(r.destination == dev_vcn_cidr for r in rt.route_rules)
        print(f"  Route to Dev VCN ({dev_vcn_cidr}): {'PASS' if has_lpg_route else 'FAIL'}")
        if not has_lpg_route:
            all_pass = False
    else:
        print("  FAIL - POC compute subnet not found")
        all_pass = False

    # 3. Check Dev compute subnet routes
    print("[3/4] Checking Dev compute subnet routes...")
    dev_subnets = net.list_subnets(dev_compartment, vcn_id=dev_vcn_id).data
    dev_compute_sub = next((s for s in dev_subnets if "compute" in s.display_name.lower()), None)
    if dev_compute_sub:
        rt = net.get_route_table(dev_compute_sub.route_table_id).data
        poc_vcn_cidr = net.get_vcn(poc_vcn_id).data.cidr_blocks[0]
        has_lpg_route = any(r.destination == poc_vcn_cidr for r in rt.route_rules)
        print(f"  Route to POC VCN ({poc_vcn_cidr}): {'PASS' if has_lpg_route else 'FAIL'}")
        if not has_lpg_route:
            all_pass = False
    else:
        print("  FAIL - Dev compute subnet not found")
        all_pass = False

    # 4. Check security lists allow ICMP
    print("[4/4] Checking ICMP rules in security lists...")
    for label, subnet in [("POC", poc_compute_sub), ("Dev", dev_compute_sub)]:
        if not subnet:
            continue
        for sl_id in subnet.security_list_ids:
            sl = net.get_security_list(sl_id).data
            icmp_ingress = [r for r in sl.ingress_security_rules if r.protocol == "1"]
            icmp_egress_or_all = [r for r in sl.egress_security_rules if r.protocol in ("1", "all")]
            has_icmp_in = len(icmp_ingress) > 0
            has_icmp_out = len(icmp_egress_or_all) > 0
            print(f"  {label} ({sl.display_name}): ICMP ingress={'PASS' if has_icmp_in else 'FAIL'}, egress={'PASS' if has_icmp_out else 'FAIL'}")
            if not has_icmp_in or not has_icmp_out:
                all_pass = False

    # Summary
    print("\n" + "=" * 60)
    if all_pass:
        print("RESULT: All network connectivity checks PASSED")
        print("  LPG peered, routes configured, ICMP allowed bidirectionally")
        sys.exit(0)
    else:
        print("RESULT: Some checks FAILED - review output above")
        sys.exit(1)


if __name__ == "__main__":
    main()
