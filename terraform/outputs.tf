# ============================================================================
# SYSTEM OUTPUTS (MANDATORY)
# ============================================================================
output "instance_id" {
  description = "MANDATORY: VM ID for Backend Management"
  value = var.use_mock_provider ? "mock-instance-id" : openstack_compute_instance_v2.nodejs_server[0].id
}

output "app_name" {
  description = "MANDATORY: Der Name der Anwendung für das Backend-Management"
  value       = var.app_name
}
# ============================================================================
# PUBLIC OUTPUTS
# ============================================================================

output "ssh_command" {
  value = "ssh <username>@${var.use_mock_provider ? "mock-ip" : openstack_networking_floatingip_v2.nodejs_fip[0].address}"
}

output "app_url" {
  value = var.use_mock_provider ? "http://mock-ip:3000" : "http://${openstack_networking_floatingip_v2.nodejs_fip[0].address}:3000"
}

output "admin_credentials" {
  description = "Lecturer/Admin Login"
  sensitive   = true
  value = {
    username    = replace(replace(lower(var.admin_email), "@", "_"), ".", "_")
    password    = random_password.admin_password.result
    ssh_command = "ssh ${replace(replace(lower(var.admin_email), "@", "_"), ".", "_")}@${var.use_mock_provider ? "mock-ip" : openstack_networking_floatingip_v2.nodejs_fip[0].address}"
  }
}

output "student_credentials" {
  description = "Student Logins"
  sensitive   = true
  value = {
    for email in var.student_emails : email => {
      username    = replace(replace(lower(email), "@", "_"), ".", "_")
      password    = random_password.student_passwords[email].result
      ssh_command = "ssh ${replace(replace(lower(email), "@", "_"), ".", "_")}@${var.use_mock_provider ? "mock-ip" : openstack_networking_floatingip_v2.nodejs_fip[0].address}"
      shared_folder = "/opt/${var.app_name}"
    }
  }
}

output "ssh_private_key" {
  sensitive = true
  value     = tls_private_key.nodejs_ssh_key.private_key_openssh
}
