# SSH Tokens


#variable "jenkins_key" {
#  type = "string"
#  default = "7d:19:b0:09:11:5f:81:b8:dc:08:9c:f4:3e:29:74:f1"
#}

#data "local_file" "mike_key" {
#  filename = "/home/guest/.ssh/acrewise/id_rsa.pub"
#}

resource "digitalocean_ssh_key" "deployer_ssh_key" {
  name = "Originator"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

variable "digitalocean_api_token" {}
variable "spaces_access_id" {}
variable "spaces_secret_key" {}

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
  keys = [digitalocean_ssh_key.deployer_ssh_key.fingerprint]
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
    digitalocean_ssh_key.deployer_ssh_key.fingerprint,
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
    digitalocean_ssh_key.deployer_ssh_key.fingerprint,
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
    source_addresses = module.CouchDB.salt_minion_private_ips
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "4369"
    source_addresses = module.CouchDB.salt_minion_private_ips
  }
  
}

module "WebRedirectEndpoint" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  
  name = "web-redirect"
  size = "s-1vcpu-1gb"
  domain_id = "terragon.us"
  keys = [
    module.Salt_Master.salt_master_ssh_fingerprint,
    digitalocean_ssh_key.deployer_ssh_key.fingerprint
  ]

  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_minion_roles = ["redirect", "minion"]
  salt_master_private_ip_address = module.Salt_Master.salt_master_private_ip_address
  salt_master_public_ip_address = module.Salt_Master.salt_master_public_ip_address
}

resource "digitalocean_firewall" "web_traffic_for_redirect" {
  name="Web-To-Redirect"
  droplet_ids = module.WebRedirectEndpoint.droplet_ids
  count = module.WebRedirectEndpoint.provision ? 1 : 0

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

resource "digitalocean_record" "redirect" {
  count = module.WebRedirectEndpoint.provision ? 1 : 0
  domain = "terragon.us"
  type = "A"
  name = "@"
  value = module.WebRedirectEndpoint.salt_minion_public_ip_addresses[0]
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

resource "digitalocean_firewall" "web_traffic_for_api" {
  name="Web-To-API"
  droplet_ids = module.NodeJSApi.droplet_ids
  count = module.NodeJSApi.provision ? 1 : 0

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
