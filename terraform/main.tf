# SSH Tokens
# This is managed thru Terraform Cloud now
variable "digitalocean_api_token" {}
variable "terraform_cloud_api_token" {}
variable "mwk_key_fingerprint" {
  type = string
}

# Infrastructure Provider Tokens
provider "digitalocean" {
  token = var.digitalocean_api_token
}

provider "tfe" {
  hostname = "app.terraform.io"
  token = var.terraform_cloud_api_token
}

# Autogenerated Top Level SSH Key
resource "tls_private_key" "autogenerated" {
  algorithm = "RSA"
}

resource "tfe_ssh_key" "autogenerated" {
  name = "autogenerated-autogenerated"
  organization = "terragon"
  key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_ssh_key" "autogenerated" {
  name = "Salt Master"
  public_key = tls_private_key.autogenerated.public_key_openssh
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
  salt_master_private_ip_address = "${module.Salt_Master.private_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.public_ip_address}"
  salt_minion_droplet_ids = module.CouchDB.droplet_ids
  salt_minion_private_ips = module.CouchDB.salt_minion_private_ip_addresses
}

module "Salt_Master" {
  source = "./modules/salt-master"
  name = "saltm"
  keys = [
    var.mwk_key_fingerprint,                        # Salt Master is the only server accesible by ssh directly by staff
    digitalocean_ssh_key.autogenerated.fingerprint
  ]
  domain_id = "terragon.us"
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

module "CouchDB" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "couchdb"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["couchdb", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
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
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["nodejsapi", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}
