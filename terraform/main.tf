variable "random_nonce" {
  default = 0
}

variable "stripe_api_key" {}

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
  salt_minion_droplet_ids = concat(module.CouchDB.droplet_ids, module.HAProxyCouchDB.droplet_ids, module.NodeJSAPI.droplet_ids, module.HAProxyNodeJSAPI.droplet_ids)
  salt_minion_private_ips = concat(module.CouchDB.salt_minion_private_ip_addresses, module.HAProxyCouchDB.salt_minion_private_ip_addresses, module.NodeJSAPI.salt_minion_private_ip_addresses, module.HAProxyNodeJSAPI.salt_minion_private_ip_addresses)
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

module "Logstash" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "logstash"
  size = "c-2"
  domain_id = "terragon.us"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["logstash", "elk", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_firewall" "beats_to_logstash" {
  name="Beats-To-Logstash"
  droplet_ids = module.Logstash.droplet_ids
  count = module.Logstash.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5044"
    source_addresses = concat(
      [module.Salt_Master.private_ip_address],
      module.CouchDB.salt_minion_private_ip_addresses,
      module.HAProxyCouchDB.salt_minion_private_ip_addresses,
      module.NodeJSAPI.salt_minion_private_ip_addresses,
      module.Kibana.salt_minion_private_ip_addresses,
      module.ElasticSearch.salt_minion_private_ip_addresses,
      module.HAProxyKibana.salt_minion_private_ip_addresses,
      module.HAProxyNodeJSAPI.salt_minion_private_ip_addresses
    )

  }
  
}

module "ElasticSearch" {
  source = "./modules/salt-minion"
  node_count = 3
  provision = true
  name = "elasticsearch"
  size = "c-2"
  domain_id = "terragon.us"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["elasticsearch", "elk", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_firewall" "logstash_to_elasticsearch" {
  name="Beats-To-ElasticSearch"
  droplet_ids = module.ElasticSearch.droplet_ids
  count = module.ElasticSearch.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "9200"
    source_addresses = module.Logstash.salt_minion_private_ip_addresses
  }
  
}

module "Kibana" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "kibana"
  size = "c-4"
  domain_id = "terragon.us"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["kibana", "elk", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_firewall" "kibana_to_elasticsearch" {
  name="Kibana-To-ElasticSearch"
  droplet_ids = module.ElasticSearch.droplet_ids
  count = module.Kibana.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "9200"
    source_addresses = module.Kibana.salt_minion_private_ip_addresses
  }
  
}

module "HAProxyKibana" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "haproxy-kibana"
  size = "512mb"
  custom_fqdn = "kibana"
  domain_id = "terragon.us"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["haproxy-kibana", "haproxy", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_firewall" "haproxy_to_kibana" {
  name="HAProxy-To-Kibana"
  droplet_ids = module.Kibana.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "5601"
    source_addresses = module.HAProxyKibana.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_haproxy_kibana" {
  name="World-To-HAProxyKibana"
  droplet_ids = module.HAProxyKibana.droplet_ids

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

resource "digitalocean_record" "kibana_frontend" {
  count = length(module.Kibana.salt_minion_public_ip_addresses)
  domain = "terragon.us"
  type = "A"
  name = "kibana"
  value = module.HAProxyKibana.salt_minion_public_ip_addresses[count.index]
}

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

module "CouchDB" {
  source = "./modules/salt-minion"
  node_count = 3
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
  couch_user = random_password.couch_user.result
  couch_pass = random_password.couch_pass.result
}

module "HAProxyCouchDB" {
  source = "./modules/salt-minion"
  node_count = 1
  provision = true
  name = "haproxy-couchdb"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  custom_fqdn = "relax"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["haproxy-couchdb", "haproxy", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

resource "digitalocean_firewall" "haproxy_to_couch" {
  name="HAProxy-To-CouchDB"
  droplet_ids = module.CouchDB.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.HAProxyCouchDB.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_haproxy" {
  name="World-To-HAProxy"
  droplet_ids = module.HAProxyCouchDB.droplet_ids

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

  inbound_rule {
    protocol = "tcp"
    port_range = "9100-9200"
    source_addresses = module.CouchDB.salt_minion_private_ip_addresses
  }
  
}

# Round robin dns for haproxy instances
resource "digitalocean_record" "couchdb_frontend" {
  count = length(module.HAProxyCouchDB.salt_minion_public_ip_addresses)
  domain = "terragon.us"
  type = "A"
  name = "relax"
  value = module.HAProxyCouchDB.salt_minion_public_ip_addresses[count.index]
}

module "NodeJSAPI" {
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
  
  salt_minion_roles = ["pm2-nodejs-api", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
  couch_user = random_password.couch_user.result
  couch_pass = random_password.couch_pass.result
  stripe_api_key = var.stripe_api_key
}

module "HAProxyNodeJSAPI" {
  source = "./modules/salt-minion"
  node_count = 0
  provision = false

  name = "haproxy-nodejsapi"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  custom_fqdn = "express"
  keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]
  
  salt_minion_roles = ["haproxy-nodejs-api", "haproxy", "minion"]
  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

# Round robin dns for haproxy instances
resource "digitalocean_record" "nodejsapi_frontend" {
  count = length(module.HAProxyNodeJSAPI.salt_minion_public_ip_addresses)
  domain = "terragon.us"
  type = "A"
  name = "express"
  value = module.HAProxyNodeJSAPI.salt_minion_public_ip_addresses[count.index]
}

resource "digitalocean_firewall" "nodejsapihaproxy_to_nodejsapi" {
  name="NodeJSAPI-HAProxy-To-NodeJSApi"
  droplet_ids = module.NodeJSAPI.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "3000"
    source_addresses = module.HAProxyNodeJSAPI.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_nodejsapi_haproxy" {
  name="World-To-NodeJSApi-HAProxy"
  droplet_ids = module.HAProxyNodeJSAPI.droplet_ids

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
  droplet_ids = module.CouchDB.droplet_ids
  count = module.CouchDB.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.NodeJSAPI.salt_minion_private_ip_addresses
  }
  
}
