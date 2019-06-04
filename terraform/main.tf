# SSH Tokens


#variable "jenkins_key" {
#  type = "string"
#  default = "7d:19:b0:09:11:5f:81:b8:dc:08:9c:f4:3e:29:74:f1"
#}

#data "local_file" "mike_key" {
#  filename = "/home/guest/.ssh/acrewise/id_rsa.pub"
#}

resource "digitalocean_ssh_key" "deployer_ssh_key" {
  name = "Deployer SSH Key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

variable "digitalocean_api_token" {}
variable "spaces_access_id" {}
variable "spaces_secret_key" {}

# Infrastructure Provider Tokens
provider "digitalocean" {
  token = "${var.digitalocean_api_token}"
  spaces_access_id = "${var.spaces_access_id}"
  spaces_secret_key = "${var.spaces_secret_key}"
}



# Create a new Spaces Bucket
resource "digitalocean_spaces_bucket" "frontend" {
    name   = "www-terragon-us"
    region = "nyc3"
    acl    = "public-read"
}

module "Salt_Master" {
  source = "./modules/salt-master"
  
  name = "saltm"
  keys = ["${digitalocean_ssh_key.deployer_ssh_key.fingerprint}"]
  salt_minion_roles = ["master"]
  domain_id = "terragon.us"
}

module "Jenkins" {
  source = "./modules/salt-minion"
  provision = true
  
  name = "jenkins"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    "${digitalocean_ssh_key.deployer_ssh_key.fingerprint}",
    "${module.Salt_Master.salt_master_ssh_fingerprint}"
  ]
  
  salt_minion_roles = ["jenkins", "minion"]
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
}

module "CouchDB-A" {
  source = "./modules/salt-minion"
  provision = true
  
  name = "couchdb-a"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    "${digitalocean_ssh_key.deployer_ssh_key.fingerprint}",
    "${module.Salt_Master.salt_master_ssh_fingerprint}"
  ]
  
  salt_minion_roles = ["couchdb", "minion"]
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
}
