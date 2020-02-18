variable "salt_master_droplet_id" {}
variable "salt_master_private_ip_address" {}
variable "salt_master_public_ip_address" {}
variable "autogenerated_ssh_private_key" {}

variable "ssh_keys" {}
variable "couchdb_user" {}
variable "couchdb_pass" {}
variable "couchdb_droplet_ids" {}
variable "image" {}
variable "pm2_nodes" {}
variable "proxy_provisioned" {}
variable "proxy_size" {}
variable "api_size" {}
variable "tld" {}

module "PM2Node" {
  source = "../salt-minion"
  node_count = var.pm2_nodes
  provision = true

  name = "nodejs-pipeline"
  domain_id = var.tld
  keys = var.ssh_keys
  image = var.image
  size = var.api_size

  salt_minion_roles = ["pm3", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
  couch_user = var.couchdb_user
  couch_pass = var.couchdb_pass
  stripe_api_key = var.stripe_api_key
}

resource "digitalocean_firewall" "nodejspipeline_to_couchdb" {
  name="NodeJSPipeline-To-CouchDB"
  droplet_ids = var.couchdb_droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "5984"
    source_addresses = module.PM2Node.salt_minion_private_ip_addresses
  }

}

output "pm2_node_private_ip_addresses" {
  value = module.PM2Node.salt_minion_private_ip_addresses
}
