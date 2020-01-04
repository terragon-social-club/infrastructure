variable "logstash_workers" {}
variable "elasticsearch_workers" {}
variable "all_droplet_ips" {}
variable "salt_master_droplet_id" {}
variable "salt_master_private_ip_address" {}
variable "salt_master_public_ip_address" {}
variable "autogenerated_ssh_private_key" {}
variable "ssh_keys" {}

module "Logstash" {
  source = "../salt-minion"
  node_count = var.logstash_workers
  provision = var.logstash_workers > 0
  name = "logstash"
  size = "s-3vcpu-1gb"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["logstash", "elk", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
}

resource "digitalocean_firewall" "beats_to_logstash" {
  name="Beats-To-Logstash"
  droplet_ids = module.Logstash.droplet_ids
  count = module.Logstash.provision ? 1 : 0

  inbound_rule {
    protocol = "tcp"
    port_range = "5044"
    source_addresses = concat(var.all_droplet_ips,
      module.ElasticSearch.salt_minion_private_ip_addresses,
      module.Logstash.salt_minion_private_ip_addresses,
      module.Kibana.salt_minion_private_ip_addresses,
      module.HAProxyKibana.salt_minion_private_ip_addresses)

  }
  
}

module "ElasticSearch" {
  source = "../salt-minion"
  node_count = var.elasticsearch_workers
  provision = var.elasticsearch_workers > 0
  name = "elasticsearch"
  size = "s-3vcpu-1gb"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["elasticsearch", "elk", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
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
  source = "../salt-minion"
  node_count = (var.elasticsearch_workers > 0) ? 1 : 0
  provision = var.elasticsearch_workers > 0
  name = "kibana"
  size = "s-8vcpu-32gb"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["kibana", "elk", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
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

module "HAProxy" {
  source = "../salt-minion"
  node_count = (var.elasticsearch_workers > 0) ? 1 : 0
  provision = true
  name = "haproxy-kibana"
  size = "s-1vcpu-1gb"
  custom_fqdn = "kibana"
  domain_id = "terragon.us"
  keys = var.ssh_keys
  
  salt_minion_roles = ["haproxy-kibana", "haproxy", "minion"]
  salt_master_droplet_id = var.salt_master_droplet_id
  salt_master_private_ip_address = var.salt_master_private_ip_address
  salt_master_public_ip_address = var.salt_master_public_ip_address
  autogenerated_ssh_private_key = var.autogenerated_ssh_private_key
}

resource "digitalocean_firewall" "haproxy_to_kibana" {
  name="HAProxy-To-Kibana"
  droplet_ids = module.Kibana.droplet_ids

  inbound_rule {
    protocol = "tcp"
    port_range = "5601"
    source_addresses = module.HAProxy.salt_minion_private_ip_addresses
  }
  
}

resource "digitalocean_firewall" "world_to_haproxy_kibana" {
  name="World-To-HAProxyKibana"
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

resource "digitalocean_record" "kibana_frontend" {
  count = (var.elasticsearch_workers > 0) ? 1 : 0
  domain = "terragon.us"
  type = "A"
  name = "kibana"
  value = module.HAProxy.salt_minion_public_ip_addresses[0]
}
