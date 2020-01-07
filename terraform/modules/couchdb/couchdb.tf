variable "random_nonce" {
  default = 0
}

variable "couchdb_replicas" {}
variable "couchdb_proxy_online" {}
variable "salt_master_droplet_id" {}
variable "salt_master_private_ip_address" {}
variable "salt_master_public_ip_address" {}
variable "autogenerated_ssh_private_key" {}
variable "ssh_keys" {}

resource "random_integer" "couch_admin_user_length" {
  min = 10
  max = 20
  keepers = {
    listener_arn = "${var.random_nonce}"
  }

}

resource "random_integer" "couch_admin_password_length" {
  min = 20
  max = 30
  keepers = {
    listener_arn = "${var.random_nonce}"
  }

}

resource "random_password" "couch_user" {
  length = random_integer.couch_admin_user_length.result
  special = false
  upper = true
  lower = true
  number = true
}

resource "random_password" "couch_pass" {
  length = random_integer.couch_admin_password_length.result
  special = false
  upper = true
  lower = true
  number = true
}

module "CouchDBNode" {
  source = "../salt-minion"
  node_count = var.couchdb_replicas
  provision = var.couchdb_replicas > 0
  name = "couchdb"
  size = "c-8"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["couchdb", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
  couch_user = random_password.couch_user.result
  couch_pass = random_password.couch_pass.result
}

module "HAProxy" {
  source = "../salt-minion"
  node_count = var.couchdb_proxy_online == true ? 1 : 0
  provision = var.couchdb_proxy_online
  name = "haproxy-couchdb"
  size = "c-8"
  domain_id = "terragon.us"
  custom_fqdn = "couchdb"
  keys = var.ssh_keys
  
  salt_minion_roles = ["couchdb", "haproxy", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
}

resource "digitalocean_firewall" "haproxy_to_couch" {
  name="HAProxy-To-CouchDB"
  droplet_ids = module.CouchDBNode.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.HAProxy.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_haproxy" {
  name="World-To-HAProxy"
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

resource "digitalocean_firewall" "couchdb_to_couchdb" {
  name="CouchDB-To-CouchDB"
  droplet_ids = module.CouchDBNode.droplet_ids
  count = module.CouchDBNode.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.CouchDBNode.salt_minion_private_ip_addresses
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "4369"
    source_addresses = module.CouchDBNode.salt_minion_private_ip_addresses
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "9100-9200"
    source_addresses = module.CouchDBNode.salt_minion_private_ip_addresses
  }
  
}

# Round robin dns for haproxy instances // currently not really round robin. this is broke and only supports one node
resource "digitalocean_record" "couchdb_frontend" {
  count = var.couchdb_proxy_online == true ? 1 : 0
  domain = "terragon.us"
  type = "A"
  name = "couchdb"
  value = element(module.HAProxy.salt_minion_public_ip_addresses, 0)
}

output "couchdb_node_private_ip_addresses" {
  value = module.CouchDBNode.salt_minion_private_ip_addresses
}

output "droplet_ids" {
  value = module.CouchDBNode.droplet_ids
}

output "haproxy_private_ip_addresses" {
  value = module.HAProxy.salt_minion_private_ip_addresses
}

output "user" {
  value = random_password.couch_user.result
}

output "pass" {
  value = random_password.couch_pass.result
}