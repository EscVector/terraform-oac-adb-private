output "poc_instance_id" { value = oci_core_instance.poc.id }
output "poc_private_ip" { value = oci_core_instance.poc.private_ip }

output "dev_instance_id" { value = oci_core_instance.dev.id }
output "dev_private_ip" { value = oci_core_instance.dev.private_ip }

output "ssh_private_key_pem" {
  value     = tls_private_key.compute.private_key_pem
  sensitive = true
}

output "ssh_public_key_openssh" {
  value = tls_private_key.compute.public_key_openssh
}

output "bastion_id" {
  description = "OCID of the POC bastion"
  value       = oci_bastion_bastion.poc.id
}

output "connectivity_validation_id" {
  description = "ID of the connectivity validation resource (non-null means validation ran)"
  value       = null_resource.validate_connectivity.id
}
