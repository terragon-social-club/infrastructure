variable "pm2_nodes" {}

variable "salt_master_droplet_id" {}
variable "salt_master_private_ip_address" {}
variable "salt_master_public_ip_address" {}
variable "autogenerated_ssh_private_key" {}

variable "ssh_keys" {}
variable "couchdb_user" {}
variable "couchdb_pass" {}
variable "stripe_api_key" {}
variable "couchdb_droplet_ids" {}

module "PM2Node" {
  source = "../salt-minion"
  node_count = var.pm2_nodes
  provision = false
  
  name = "nodejs-api"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["pm2", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
  couch_user = var.couchdb_user
  couch_pass = var.couchdb_pass
  stripe_api_key = var.stripe_api_key
}

module "HAProxy" {
  source = "../salt-minion"
  node_count = var.pm2_nodes > 0 ? 1 : 0
  provision = false

  name = "haproxy-nodejsapi"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  custom_fqdn = "express"
  keys = var.ssh_keys
  
  salt_minion_roles = ["haproxy", "pm2", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
}

# Round robin dns for haproxy instances
resource "digitalocean_record" "nodejsapi_frontend" {
  count = var.pm2_nodes > 0 ? 1 : 0
  domain = "terragon.us"
  type = "A"
  name = "express"
  value = module.HAProxy.salt_minion_public_ip_addresses[0]
}

resource "digitalocean_firewall" "nodejsapihaproxy_to_nodejsapi" {
  name="NodeJSAPI-HAProxy-To-NodeJSApi"
  droplet_ids = module.PM2Node.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "3000"
    source_addresses = module.HAProxy.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_nodejsapi_haproxy" {
  name="World-To-NodeJSApi-HAProxy"
  droplet_ids = module.HAProxy.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "443"
    source_addresses = ["0.0.0.0/0"]
  }
  
}

resource "digitalocean_firewall" "nodejsapi_to_couchdb" {
  name="NodeJSApi-To-CouchDB"
  droplet_ids = var.couchdb_droplet_ids
  count = var.couchdb_droplet_ids.length > 0 ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.PM2Node.salt_minion_private_ip_addresses
  }
  
}

output "pm2_node_private_ip_addresses" {
  value = module.PM2Node.*.salt_minion_private_ip_addresses
}

output "haproxy_private_ip_addresses" {
  value = module.HAProxy.*.salt_minion_private_ip_addresses
}
