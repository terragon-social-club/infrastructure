variable "stripe_api_key" {}
variable "digitalocean_api_token" {}
variable "terraform_cloud_api_token" {}
variable "geoip_license_key" {}
variable "geoip_account_id" {}

variable "mwk_key_fingerprint" {
  type = string
}

provider "digitalocean" {
  token = var.digitalocean_api_token
}

provider "tfe" {
  hostname = "app.terraform.io"
  token = var.terraform_cloud_api_token
}

resource "tls_private_key" "autogenerated" {
  algorithm = "RSA"
}

resource "digitalocean_ssh_key" "autogenerated" {
  name = "Salt Master"
  public_key = tls_private_key.autogenerated.public_key_openssh
}

variable "base_image" {
  default = "freebsd-12-x64-zfs"
}

variable "cluster_makeup" {
  default = {
    tld = "terragon.us"

    salt_master = {
      size = "s-1vcpu-1gb"
    }

    logging = {
      heartbeat_provisioned = true
      heartbeat_size = "s-1vcpu-1gb"
      elastic_size = "s-2vcpu-4gb"
      kibana_proxy_size = "s-1vcpu-1gb"
      kibana_size = "s-2vcpu-2gb"
      kibana_proxy_provisioned = true
      kibana_domain = "dashboard"
      logstash_size = "s-1vcpu-1gb"
      logstash_node_count = 1
      elastic_node_count = 1
    }

    couchdb = {
      couch_size = "s-1vcpu-1gb"
      proxy_size = "s-1vcpu-1gb"
      proxy_provisioned = true
      haproxy_domain = "couchdb"
      node_count = 3
    }

    api = {
      api_size = "s-1vcpu-1gb"
      proxy_size = "s-1vcpu-1gb"
      api_node_count = 1
      proxy_provisioned = true
    }

    angular = {
      size = "s-1vcpu-1gb"
    }

  }

}

module "Mail" {
  source = "./modules/mail"
  tld = var.cluster_makeup.tld
}

resource "digitalocean_firewall" "ping_all_public" {
  name="all-public-pinged"
  droplet_ids = concat(
    [module.Salt_Master.droplet_id]
  )

  inbound_rule {
    protocol = "icmp"
    source_addresses = ["0.0.0.0/1"]
  }

}

module "Salt_Master" {
  source = "./modules/salt-master"
  name = "saltm"
  tld = var.cluster_makeup.tld

  keys = [
    var.mwk_key_fingerprint,                        # Salt Master is the only server accesible by ssh directly by staff. Enforced by key auth & firewall rules
    digitalocean_ssh_key.autogenerated.fingerprint
  ]

  disk_size = 1
  image = var.base_image
  size = var.cluster_makeup.salt_master.size
  domain_id = var.cluster_makeup.tld
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem
}

module "ELK" {
  source = "./modules/elk"
  image = var.base_image
  tld = var.cluster_makeup.tld

  kibana_domain = var.cluster_makeup.logging.kibana_domain
  kibana_size = var.cluster_makeup.logging.kibana_size
  kibana_proxy_size = var.cluster_makeup.logging.kibana_proxy_size
  kibana_proxy_provisioned = var.cluster_makeup.logging.kibana_proxy_provisioned
  logstash_size = var.cluster_makeup.logging.logstash_size
  logstash_workers = var.cluster_makeup.logging.logstash_node_count
  elasticsearch_workers = var.cluster_makeup.logging.elastic_node_count
  elasticsearch_size = var.cluster_makeup.logging.elastic_size
  heartbeat_size = var.cluster_makeup.logging.heartbeat_size
  heartbeat_provisioned = var.cluster_makeup.logging.heartbeat_provisioned
  heartbeat_access_droplet_ids = module.CouchDB.droplet_ids

  geoip_license_key = var.geoip_license_key
  geoip_account_id = var.geoip_account_id

  all_droplet_ips = concat(
    [module.Salt_Master.private_ip_address],
    module.CouchDB.couchdb_node_private_ip_addresses,
    module.CouchDB.haproxy_private_ip_addresses,
    module.NodeJSApi.pm2_node_private_ip_addresses,
    module.NodeJSApi.haproxy_private_ip_addresses
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
  image = var.base_image
  tld = var.cluster_makeup.tld

  haproxy_domain = var.cluster_makeup.couchdb.haproxy_domain
  couchdb_size = var.cluster_makeup.couchdb.couch_size
  proxy_size = var.cluster_makeup.couchdb.proxy_size
  couchdb_replicas = var.cluster_makeup.couchdb.node_count
  couchdb_proxy_online = var.cluster_makeup.couchdb.proxy_provisioned

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
  image = var.base_image
  tld = var.cluster_makeup.tld

  api_size = var.cluster_makeup.api.api_size
  proxy_size = var.cluster_makeup.api.proxy_size
  proxy_provisioned = var.cluster_makeup.api.proxy_provisioned
  pm2_nodes = var.cluster_makeup.api.api_node_count
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

module "NodeJSPipeline" {
  source = "./modules/nodejspipeline"
  image = var.base_image
  tld = var.cluster_makeup.tld

  api_size = var.cluster_makeup.api.api_size
  proxy_size = var.cluster_makeup.api.proxy_size
  proxy_provisioned = var.cluster_makeup.api.proxy_provisioned
  pm2_nodes = var.cluster_makeup.api.api_node_count
  couchdb_user = module.CouchDB.user
  couchdb_pass = module.CouchDB.pass
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

module "Angular" {
  source = "./modules/angular"
  image = var.base_image
  tld = var.cluster_makeup.tld
  size = var.cluster_makeup.angular.size

  salt_master_droplet_id = module.Salt_Master.droplet_id
  salt_master_private_ip_address = module.Salt_Master.private_ip_address
  salt_master_public_ip_address = module.Salt_Master.public_ip_address
  autogenerated_ssh_private_key = tls_private_key.autogenerated.private_key_pem

  ssh_keys = [
    digitalocean_ssh_key.autogenerated.fingerprint,
    module.Salt_Master.ssh_fingerprint
  ]

}
