# SSH Tokens
# This is managed thru Terraform Cloud now
variable "digitalocean_api_token" {}
variable "generated_key" {
  default = "c6:c4:6f:23:f0:50:09:f6:55:28:ca:62:57:7f:00:c8"
}

# Infrastructure Provider Tokens
provider "digitalocean" {
  token = var.digitalocean_api_token
}

# Mail Records
resource "digitalocean_record" "hushmail-1" {
  domain = "terragon.us"
  type = "MX"
  name = "@"
  value = "plsmtp2.hushmail.com."
  priority = "10"
}

resource "digitalocean_record" "hushmail-2" {
  domain = "terragon.us"
  type = "MX"
  name = "@"
  value = "plsmtp1.hushmail.com."
  priority = "10"
}

module "Firewalls" {
  source = "./modules/firewall"
  salt_master_droplet_id = "${module.Salt_Master.droplet_id}"
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_private_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_minion_droplet_ids = module.CouchDB.droplet_ids
  salt_minion_private_ips = module.CouchDB.salt_minion_private_ip_addresses
}

module "Salt_Master" {
  source = "./modules/salt-master"
  name = "saltm"
  keys = [var.generated_key]
  salt_minion_roles = ["master"]
  domain_id = "terragon.us"
}

module "Jenkins" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "jenkins"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    var.generated_key,
    module.Salt_Master.salt_master_ssh_fingerprint
  ]
  
  salt_minion_roles = ["jenkins", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.salt_master_private_ip_address
  salt_master_public_ip_address = module.Salt_Master.salt_master_public_ip_address
}

resource "digitalocean_firewall" "web_traffic_for_jenkins" {
  name="Web-To-Jenkins"
  droplet_ids = module.Jenkins.droplet_ids
  count = module.Jenkins.provision ? 1 : 0

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

module "CouchDB" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "couchdb"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    var.generated_key,
    module.Salt_Master.salt_master_ssh_fingerprint
  ]
  
  salt_minion_roles = ["couchdb", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.salt_master_private_ip_address
  salt_master_public_ip_address = module.Salt_Master.salt_master_public_ip_address
}

resource "digitalocean_firewall" "web_traffic_for_couchdb" {
  name="Web-To-CouchDB"
  droplet_ids = module.CouchDB.droplet_ids
  count = module.CouchDB.provision ? 1 : 0

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
  droplet_ids = module.CouchDB.droplet_ids
  count = module.CouchDB.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.CouchDB.salt_minion_private_ip_addresses
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "4369"
    source_addresses = module.CouchDB.salt_minion_private_ip_addresses
  }
  
}

module "NodeJSApi" {
  source = "./modules/salt-minion"
  node_count = 0
  provision = false
  
  name = "nodejs-api"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    module.Salt_Master.salt_master_ssh_fingerprint,
    digitalocean_ssh_key.deployer_ssh_key.fingerprint
  ]
  
  salt_minion_roles = ["nodejsapi", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.salt_master_private_ip_address
  salt_master_public_ip_address = module.Salt_Master.salt_master_public_ip_address
}
