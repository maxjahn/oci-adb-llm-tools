provider "oci" {}

variable "compartment_ocid" {}

variable "adb_admin_password" {
  default = ""
  sensitive = true
}

variable "adb_name" {
  default = "ADBV"
}

variable "adb_display_name" {
  default = "ADB-Vector"
}

resource "oci_database_autonomous_database" "oci_database_autonomous_database" {
	admin_password = var.adb_admin_password
	autonomous_maintenance_schedule_type = "REGULAR"
	compartment_id = "${var.compartment_ocid}"
	compute_count = "2"
	compute_model = "ECPU"
	data_storage_size_in_gb = "1024"
	db_name = var.adb_name
	db_version = "23ai"
	db_workload = "OLTP"
	display_name = var.adb_display_name
	is_auto_scaling_enabled = "false"
	is_auto_scaling_for_storage_enabled = "false"
	is_dedicated = "false"
	is_free_tier = "true"
	is_mtls_connection_required = "false"
	is_preview_version_with_service_terms_accepted = "false"
	license_model = "LICENSE_INCLUDED"
	whitelisted_ips = [
		"0.0.0.0/0",
	]
}