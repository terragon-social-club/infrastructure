# SSH Tokens
variable "mike_key" {
  type = "string"
  default = "2e:05:a5:d1:0f:9e:d8:4e:06:af:20:e7:d4:8b:7b:96"
}

variable "salt_master_key" {
  type = "string"
  default = "49:a2:23:92:fd:ec:8d:be:27:b8:b7:a6:a3:4a:77:7e"
}

#variable "jenkins_key" {
#  type = "string"
#  default = "7d:19:b0:09:11:5f:81:b8:dc:08:9c:f4:3e:29:74:f1"
#}

variable "digitalocean_api_token" {}

# Infrastructure Provider Tokens
provider "digitalocean" {
  token = "${var.digitalocean_api_token}"
}

module "Salt_Master" {
  source = "modules/salt"
  master = true
  name = "saltm"
  key = ["${var.mike_key}"]
  salt_minion_roles = ["  - master"]
  domain_id = "terragon.us"
}

#module "CouchDBMasterNode" {
#  source = "modules/salt"
#  minion = true
#  name = "couchdb-a"
#  tld = "terragon.us"
  #image = "ubuntu-16-04-x64"
#  size = "512mb"
#  static_ip = true
#  is_ubuntu = false
#  is_bsd = true
#  create_tld = false
#  domain_id = "terragon.us"
#  key = ["${var.mike_key}"]
#  salt_master_fqdn = "${module.Salt_Master.salt_master_fqdn}"
#  salt_minion_roles = ["  - couchdb", "  - minion", "  - couchdbmaster"]
#  salt_master_private_ip_address = "${module.Salt_Master.salt_master_private_ip_address}"
#  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
#}
