# SSH Tokens


#variable "jenkins_key" {
#  type = "string"
#  default = "7d:19:b0:09:11:5f:81:b8:dc:08:9c:f4:3e:29:74:f1"
#}

#data "local_file" "mike_key" {
#  filename = "/home/guest/.ssh/acrewise/id_rsa.pub"
#}

resource "digitalocean_ssh_key" "mike_keen_key" {
  name = "Mike Keen Key"
  public_key = "${file("/home/guest/.ssh/id_rsa.pub")}"
}

variable "digitalocean_api_token" {}

# Infrastructure Provider Tokens
provider "digitalocean" {
  token = "${var.digitalocean_api_token}"
}

module "Salt_Master" {
  source = "./modules/salt-master"
  name = "saltm"
  keys = ["${digitalocean_ssh_key.mike_keen_key.fingerprint}"]
  salt_minion_roles = ["  - master"]
  domain_id = "terragon.us"
}

module "Jenkins" {
  source = "./modules/salt-minion"
  provision = true
  name = "jenkins"
  size = "512mb"
  domain_id = "terragon.us"
  keys = [
    "${digitalocean_ssh_key.mike_keen_key.fingerprint}",
    "${module.Salt_Master.salt_master_ssh_fingerprint}"
  ]
  
  salt_minion_roles = ["  - jenkins", "  - minion"]
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
}
