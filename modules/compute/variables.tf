variable "poc_compartment_ocid" { type = string }
variable "dev_compartment_ocid" { type = string }
variable "ad_name" { type = string }
variable "poc_vcn_id" { type = string }
variable "dev_vcn_id" { type = string }
variable "poc_compute_subnet_id" { type = string }
variable "dev_compute_subnet_id" { type = string }
variable "instance_shape" { type = string }
variable "instance_shape_ocpus" { type = number }
variable "instance_shape_memory_in_gbs" { type = number }
variable "instance_image_ocid" { type = string }
variable "freeform_tags" { type = map(string) }

variable "bastion_client_cidr_allow_list" {
  description = "CIDR blocks allowed to connect to the bastion (e.g. your public IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_max_session_ttl" {
  description = "Maximum session TTL in seconds for bastion sessions"
  type        = number
  default     = 10800
}
