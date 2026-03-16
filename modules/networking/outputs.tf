output "poc_vcn_id" { value = oci_core_vcn.poc.id }
output "dev_vcn_id" { value = oci_core_vcn.dev.id }

output "adb_subnet_id" { value = oci_core_subnet.adb_private.id }
output "oac_pac_subnet_id" { value = oci_core_subnet.oac_pac.id }
output "dev_db_subnet_id" { value = oci_core_subnet.dev_db.id }

output "nsg_adb_private_id" { value = oci_core_network_security_group.adb_private.id }
output "nsg_oac_pac_id" { value = oci_core_network_security_group.oac_pac.id }

output "lpg_poc_to_dev_id" { value = oci_core_local_peering_gateway.poc_to_dev.id }
output "lpg_dev_to_poc_id" { value = oci_core_local_peering_gateway.dev_to_poc.id }

output "lpg_peering_status" { value = oci_core_local_peering_gateway.poc_to_dev.peering_status }
