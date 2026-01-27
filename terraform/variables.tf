# ============================================================================
# SYSTEM VARIABLES (MANDATORY)
# ============================================================================

variable "deployment_id" { 
  description = "Unique deployment identifier"
  type        = string
  
  validation {
    condition     = length(var.deployment_id) > 0
    error_message = "deployment_id must not be empty."
  }
}

variable "use_mock_provider" { 
  description = "Use mock provider for testing"
  type        = bool
  default     = false 
}

# ============================================================================
# USER INPUTS (VALIDATED CONTRACT)
# ============================================================================

variable "project_name" {
  description = "Name of the project (used for hostname and folder)"
  type        = string
  
  validation {
    # Regex: 3-20 Zeichen, Kleinbuchstaben, Zahlen, Bindestrich, Unterstrich
    condition     = can(regex("^[a-zA-Z0-9-_]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters (letters, numbers, -, _)."
  }
}

variable "admin_email" {
  description = "Email address of the lecturer (admin)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "The admin_email is invalid."
  }
}

variable "student_emails" {
  description = "List of student emails"
  type        = list(string)
  
  validation {
    # YAML Limit: Max 10 Students
    condition     = length(var.student_emails) > 0 && length(var.student_emails) <= 10
    error_message = "You must provide between 1 and 10 student emails."
  }

  validation {
    # Prüft, ob ALLE E-Mails im Array valide sind
    condition = alltrue([
      for email in var.student_emails : can(regex("^\\S+@\\S+\\.\\S+$", email))
    ])
    error_message = "All items in student_emails must be valid email addresses."
  }
}

variable "flavor_name" {
  description = "Hardware Quota"
  type        = string
  default     = "gp1.medium"

  validation {
    # Whitelist Check
    condition     = contains(["gp1.small", "gp1.medium", "gp1.large"], var.flavor_name)
    error_message = "Invalid flavor. Allowed: gp1.small, gp1.medium, gp1.large."
  }
}

variable "node_version" {
  description = "Node.js Runtime Version"
  type        = string
  default     = "20"

  validation {
    condition     = contains(["18", "20"], var.node_version)
    error_message = "Node version must be '18' or '20'."
  }
}

variable "git_repo_url" {
  description = "Optional Git Repository to clone"
  type        = string
  default     = ""

  validation {
    # Erlaubt leeren String ODER validen HTTP(S) Git Link
    condition     = var.git_repo_url == "" || can(regex("^https?://.*\\.git$", var.git_repo_url))
    error_message = "Git URL must start with http(s):// and end with .git (or be empty)."
  }
}

# ============================================================================
# INFRASTRUCTURE DEFAULTS
# ============================================================================

variable "image_name" { 
  type    = string
  default = "Ubuntu 22.04" 
}

variable "network_name" { 
  type    = string
  default = "NAT" 
}

variable "external_network_name" { 
  type    = string
  default = "DHBW" 
}

variable "floating_ip_pool" { 
  type    = string
  default = "DHBW" 
}