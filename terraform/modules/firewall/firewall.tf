variable "salt_minion_droplet_ids" {
  type = "list"
}

variable "salt_master_droplet_id" {
  type = "string"
}

variable "salt_minion_private_ips" {
  type = "list"
}

variable "salt_master_private_ip_address" {
  type = "string"
}

variable "salt_master_public_ip_address" {
  type = "string"
}

resource "digitalocean_firewall" "ssh_salt_master_to_minions_private" {
  name="SSH-Salt-Master-To-Minions"
  droplet_ids = "${var.salt_minion_droplet_ids}"

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["${var.salt_master_private_ip_address}"]
  }
  
}

resource "digitalocean_firewall" "ssh_public_to_salt_master_public" {
  name="Public-To-Salt-Master"
  droplet_ids = ["${var.salt_master_droplet_id}"]
  
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  
}

resource "digitalocean_firewall" "minions_to_salt_master_public" {
  name="Minions-To-Salt-Master"
  droplet_ids = ["${var.salt_master_droplet_id}"]
  
  inbound_rule {
    protocol = "tcp"
    port_range = "4505-4506"
    source_addresses = ["0.0.0.0/0"]
  }
  
}

resource "digitalocean_firewall" "minions_master_ping_each_other" {
  name="Minions-Master-Ping-Each-Other"
  droplet_ids = concat(["${var.salt_master_droplet_id}"], "${var.salt_minion_droplet_ids}")
  
  inbound_rule {
    protocol = "icmp"
    source_addresses = concat("${var.salt_minion_private_ips}", ["${var.salt_master_private_ip_address}"])
  }
  
}

resource "digitalocean_firewall" "basic_traffic_flow" {
  name="Basic-Rules"
  droplet_ids = concat(["${var.salt_master_droplet_id}"], "${var.salt_minion_droplet_ids}")
  
  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  
  outbound_rule {
    protocol = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
  
  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  
}
