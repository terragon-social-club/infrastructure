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

# Mail Records
resource "digitalocean_record" "hushmail-1" {
  domain = "terragon.us"
  type = "MX"
  name = "@"
  value = "plsmtp2.hushmail.com"
  priority = "10"
}

resource "digitalocean_record" "hushmail-2" {
  domain = "terragon.us"
  type = "MX"
  name = "@"
  value = "plsmtp1.hushmail.com"
  priority = "10"
}

resource "digitalocean_spaces_bucket" "frontend" {
  name = "www-terragon-us"
  region = "nyc3"
  acl = "public-read"
}

resource "digitalocean_record" "cloudfront_www" {
  domain = "terragon.us"
  type = "CNAME"
  name = "www"
  value = "dshnklusv3rdp.cloudfront.net"
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

module "CouchDB-B" {
  source = "./modules/salt-minion"
  provision = false
  
  name = "couchdb-b"
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

module "WebRedirectEndpoint" {
  source = "./modules/salt-minion"
  provision = true
  
  name = "web-redirect"
  size = "s-1vcpu-1gb"
  domain_id = "terragon.us"
  keys = [
    "${digitalocean_ssh_key.deployer_ssh_key.fingerprint}",
    "${module.Salt_Master.salt_master_ssh_fingerprint}"
  ]
  
  salt_minion_roles = ["redirect", "minion"]
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
}

resource "digitalocean_record" "redirect" {
  count = "${module.WebRedirectEndpoint.provision ? 1 : 0}" 
  domain = "terragon.us"
  type = "A"
  name = "@"
  value = "${module.WebRedirectEndpoint.salt_minion_public_ip_address}"
}

module "NodeJSApi-A" {
  source = "./modules/salt-minion"
  provision = true
  
  name = "nodejs-api-a"
  size = "s-2vcpu-2gb"
  domain_id = "terragon.us"
  keys = [
    "${digitalocean_ssh_key.deployer_ssh_key.fingerprint}",
    "${module.Salt_Master.salt_master_ssh_fingerprint}"
  ]
  
  salt_minion_roles = ["nodejsapi", "minion"]
  salt_master_private_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
  salt_master_public_ip_address = "${module.Salt_Master.salt_master_public_ip_address}"
}
