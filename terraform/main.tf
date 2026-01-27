terraform {
  required_version = ">= 1.6.0"
  required_providers {
    openstack = { 
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0" 
    }
    tls = { 
      source  = "hashicorp/tls"
      version = "~> 4.0" 
    }
    random = { 
      source  = "hashicorp/random"
      version = "~> 3.5" 
    }
    null = { 
      source  = "hashicorp/null"
      version = "~> 3.2" 
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}


# --- Data Sources ---
data "openstack_images_image_v2" "ubuntu" {
  count       = var.use_mock_provider ? 0 : 1
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "selected" {
  count = var.use_mock_provider ? 0 : 1
  name  = var.flavor_name
}

data "openstack_networking_network_v2" "external" {
  count    = var.use_mock_provider ? 0 : 1
  name     = var.external_network_name
  external = true
}

# --- Credentials ---
resource "random_password" "student_passwords" {
  for_each         = toset(var.student_emails)
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "admin_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}

resource "tls_private_key" "nodejs_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "nodejs_keypair" {
  count      = var.use_mock_provider ? 0 : 1
  name       = "nodejs-keypair-${var.deployment_id}"
  public_key = tls_private_key.nodejs_ssh_key.public_key_openssh
}

# --- Security Group ---
resource "openstack_networking_secgroup_v2" "nodejs_access" {
  count = var.use_mock_provider ? 0 : 1
  name  = "nodejs-access-${var.deployment_id}"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.nodejs_access[0].id
}

resource "openstack_networking_secgroup_rule_v2" "app_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3000
  port_range_max    = 3000
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.nodejs_access[0].id
}

resource "openstack_networking_secgroup_rule_v2" "alt_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.nodejs_access[0].id
}

# --- Instance ---
resource "openstack_compute_instance_v2" "nodejs_server" {
  count           = var.use_mock_provider ? 0 : 1
  name            = "nodejs-server-${var.deployment_id}"
  image_id        = data.openstack_images_image_v2.ubuntu[0].id
  flavor_id       = data.openstack_compute_flavor_v2.selected[0].id
  key_pair        = openstack_compute_keypair_v2.nodejs_keypair[0].name
  security_groups = [openstack_networking_secgroup_v2.nodejs_access[0].name]
  
  network { 
    name = var.network_name 
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    project_name = var.project_name
    node_version = var.node_version
    git_repo_url = var.git_repo_url
    
    # Admin User Processing
    admin_username = replace(replace(lower(var.admin_email), "@", "_"), ".", "_")
    admin_password = random_password.admin_password.result

    # Student User Processing
    students = [
      for email in var.student_emails : {
        username = replace(replace(lower(email), "@", "_"), ".", "_")
        password = random_password.student_passwords[email].result
      }
    ]
  })
}

# --- Floating IP ---
resource "openstack_networking_floatingip_v2" "nodejs_fip" {
  count = var.use_mock_provider ? 0 : 1
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "nodejs_fip_assoc" {
  count       = var.use_mock_provider ? 0 : 1
  floating_ip = openstack_networking_floatingip_v2.nodejs_fip[0].address
  instance_id = openstack_compute_instance_v2.nodejs_server[0].id
}

# --- Mock Resource ---
resource "null_resource" "mock_nodejs_server" {
  count = var.use_mock_provider ? 1 : 0
  triggers = {
    deployment_id = var.deployment_id
    project_name  = var.project_name
  }
}