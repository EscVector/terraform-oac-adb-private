output "oac_id" { value = oci_analytics_analytics_instance.oac.id }
output "oac_display_name" { value = oci_analytics_analytics_instance.oac.display_name }
output "oac_service_url" { value = oci_analytics_analytics_instance.oac.service_url }

output "pac_id" { value = oci_analytics_analytics_instance_private_access_channel.pac.id }
output "pac_ip_address" { value = oci_analytics_analytics_instance_private_access_channel.pac.ip_address }
output "pac_vcn_id" { value = oci_analytics_analytics_instance_private_access_channel.pac.vcn_id }
