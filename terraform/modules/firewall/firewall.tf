variable "salt_minion_droplet_ids" {
  type = list
}

variable "salt_master_droplet_id" {
  type = string
}

variable "salt_minion_private_ips" {
  type = list
}

variable "salt_master_private_ip_address" {
  type = string
}

variable "salt_master_public_ip_address" {
  type = string
}

resource "digitalocean_firewall" "minions_master_ping_each_other" {
  name="Minions-Master-Ping-Each-Other"
  droplet_ids = concat([var.salt_master_droplet_id], var.salt_minion_droplet_ids)
  
  inbound_rule {
    protocol = "icmp"
    source_addresses = concat(var.salt_minion_private_ips, [var.salt_master_private_ip_address])
  }
  
}
