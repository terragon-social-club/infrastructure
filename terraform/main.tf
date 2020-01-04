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

variable "cluster_makeup" {
  default = {
    couchdb_replicas = 0
    couchdb_proxy_online = false
    logstash_workers = 0
    elasticsearch_workers = 0
    js_api_endpoints = 0
  }

}

module "Mail" {
  source = "./modules/mail"
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

module "Firewalls" {
  source = "./modules/firewall"
  salt_master_droplet_id = "${module.Salt_Master.droplet_id}"
  salt_master_private_ip_address = "${module.Salt_Master.private_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.public_ip_address}"
  salt_minion_droplet_ids = concat(module.CouchDB.droplet_ids, module.HAProxyCouchDB.droplet_ids, module.NodeJSAPI.droplet_ids, module.HAProxyNodeJSAPI.droplet_ids)
  salt_minion_private_ips = concat(module.CouchDB.salt_minion_private_ip_addresses, module.HAProxyCouchDB.salt_minion_private_ip_addresses, module.NodeJSAPI.salt_minion_private_ip_addresses, module.HAProxyNodeJSAPI.salt_minion_private_ip_addresses)
}

module "ELK" {
  source = "./modules/elk"
  logstash_workers = var.cluster_makeup.logstash_workers
  elasticsearch_workers = var.cluster_makeup.elasticsearch_workers

  all_droplet_ips = concat(
    [module.Salt_Master.private_ip_address],
    module.CouchDB.couchdb_node_private_ip_addresses,
    module.CouchDB.haproxy_private_ip_addresses,
    module.NodeJSAPI.salt_minion_private_ip_addresses,
    module.HAProxyNodeJSAPI.salt_minion_private_ip_addresses
  )

  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem

  ssh_keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]

}

module "CouchDB" {
  source = "./modules/couchdb"
  couchdb_replicas = var.cluster_makeup.couchdb_replicas

  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem

  ssh_keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]

}

module "NodeJSApi" {
  source = "./modules/nodejsapi"
  pm2_nodes = var.cluster_makeup.js_api_endpoints
  couchdb_user = module.CouchDB.user
  couchdb_pass = module.CouchDB.pass
  stripe_api_key = var.stripe_api_key
  couchdb_droplet_ids = module.CouchDB.droplet_ids

  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem

  ssh_keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]

}
