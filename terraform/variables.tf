# ============================================================================
# System Variables
# ============================================================================
variable "deployment_id" { 
  type = string 
}

variable "use_mock_provider" { 
  type    = bool
  default = false 
}

# ============================================================================
# User Inputs
# ============================================================================
variable "project_name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters."
  }
}

variable "admin_email" {
  description = "Email address of the lecturer (admin)"
  type        = string
}

variable "student_emails" {
  type = list(string)
  validation {
    condition     = length(var.student_emails) > 0 && length(var.student_emails) <= 10
    error_message = "At least one student email is required."
  }
}

variable "flavor_name" {
  type    = string
  default = "gp1.medium"
}

variable "node_version" {
  type    = string
  default = "20"
}

variable "git_repo_url" {
  type    = string
  default = ""
}

# ============================================================================
# Infrastructure Defaults
# ============================================================================
variable "image_name" { 
  default = "Ubuntu 22.04" 
}

variable "network_name" { 
  default = "NAT" 
}

variable "external_network_name" { 
  default = "DHBW" 
}

variable "floating_ip_pool" { 
  default = "DHBW" 
}