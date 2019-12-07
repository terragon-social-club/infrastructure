variable "alpha" {
  default = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
}

variable "salt_minion_roles" {
  default = ["minion"]
}

variable "keys" {
  type = list
}

variable "node_count" {
  default = 1
}

variable "provision" { }

variable "domain_id" { }
variable "name" { }

variable "salt_master_private_ip_address" { }
variable "salt_master_public_ip_address" { }
variable "salt_master_droplet_id" { }
variable "autogenerated_ssh_private_key" { }

variable "custom_fqdn" {
  default = ""
}

variable "region" {
  default = "nyc1"
}

variable "image" {
  default = "freebsd-12-x64-zfs"
}

variable "size" {
  default = "512mb"
}

variable "couchdb_ip_addresses" {
  default = []
}

variable "nodejsapi_ip_addresses" {
  default = []
}

resource "digitalocean_droplet" "salt_minion" {
  count = var.node_count
  private_networking = true
  backups = false
  region = var.region
  image = var.image
  name = "${var.name}-${var.alpha[count.index]}"
  size = var.size
  ssh_keys = var.keys
  ipv6 = false
  
  provisioner "remote-exec" {
    when = destroy
    
    connection {
      host = var.salt_master_public_ip_address
      private_key = var.autogenerated_ssh_private_key
      user = "root"
      type = "ssh"
      timeout = "2m"
    }
    
    inline = [
      "salt-key -d ${var.name}-${var.alpha[count.index]} -y"
    ]
    
  }
 
}

resource "digitalocean_firewall" "ssh_salt_master_to_minion_private" {
  count = var.provision ? 1 : 0
  name="SSH-Salt-Master-To-${var.name}-Private"
  droplet_ids = digitalocean_droplet.salt_minion.*.id

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = [var.salt_master_private_ip_address]
  }
 
}

resource "digitalocean_firewall" "all_outbound" {
  count = var.provision ? 1 : 0
  name="All-${var.name}-Outbound"
  droplet_ids = digitalocean_droplet.salt_minion.*.id

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

resource "digitalocean_firewall" "salt_salt_minion_to_salt_master_private" {
  count = var.provision ? 1 : 0
  name="Salt-${var.name}-To-Salt-Master-Private"
  droplet_ids = [var.salt_master_droplet_id]
  
  inbound_rule {
    protocol = "tcp"
    port_range = "4505-4506"
    source_addresses = digitalocean_droplet.salt_minion.*.ipv4_address_private
  }
  
}

resource "null_resource" "configure_firewalled_minion" {
  count = var.node_count
  
  triggers = {
    id = digitalocean_droplet.salt_minion[count.index].id
  }

  depends_on = [
    digitalocean_firewall.ssh_salt_master_to_minion_private,
    digitalocean_firewall.all_outbound,
    digitalocean_firewall.salt_salt_minion_to_salt_master_private,
  ]

  connection {
    bastion_host = var.salt_master_public_ip_address
    private_key = var.autogenerated_ssh_private_key
    host = element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)
    user = "root"
    type = "ssh"
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "fetch -o /tmp/bootstrap-salt.sh https://bootstrap.saltstack.com",
      "sh /tmp/bootstrap-salt.sh -P -X -A ${var.salt_master_private_ip_address} -i ${var.name}-${var.alpha[count.index]}",
      "mkdir -p /usr/local/etc/salt/pki/minion"
    ]
    
  }
  
  provisioner "file" {
    content = "roles:\n${join("\n", [for role in var.salt_minion_roles : "  - ${role}"])}\nfqdn: ${length(var.custom_fqdn) > 0 ? var.custom_fqdn : "${var.name}-${var.alpha[count.index]}"}.terragon.us\nprivate_ip_address: ${element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)}\npublic_ip_address: ${element(digitalocean_droplet.salt_minion.*.ipv4_address, count.index)}\ncouchdb_ip_addresses: [${join(",", [for address in var.couchdb_ip_addresses : "'${address}'"])}]\nodejsapi_ip_addresses: [${join(",", [for address in var.nodejsapi_ip_addresses : "'${address}'"])}]"
    destination = "/usr/local/etc/salt/grains"
  }

  provisioner "file" {
    source = "${path.module}/../98-minion-config.conf"
    destination = "/usr/local/etc/salt/minion.d/98-minion-config.conf"
  }

}

resource "null_resource" "bootstrap_salt_keys" {
  count = var.node_count
  
  depends_on = [
    null_resource.configure_firewalled_minion
  ]

  triggers = {
    id = digitalocean_droplet.salt_minion[count.index].id
  }

  provisioner "remote-exec" {
    connection {
      host = var.salt_master_public_ip_address
      private_key = var.autogenerated_ssh_private_key
      user = "root"
      type = "ssh"
      timeout = "2m"
    }

    inline = [
      "salt-key --gen-keys=${var.name}-${var.alpha[count.index]}",
      "mkdir -p /usr/local/etc/salt/pki/master/minions",
      "cp ${var.name}-${var.alpha[count.index]}.pub /usr/local/etc/salt/pki/master/minions/${var.name}-${var.alpha[count.index]}",
      "scp -o 'StrictHostKeyChecking no' ${var.name}-${var.alpha[count.index]}.pub root@${element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)}:/usr/local/etc/salt/pki/minion/minion.pub",
      "scp -o 'StrictHostKeyChecking no' ${var.name}-${var.alpha[count.index]}.pem root@${element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)}:/usr/local/etc/salt/pki/minion/minion.pem",
      "rm ${var.name}-${var.alpha[count.index]}.pub",
      "rm ${var.name}-${var.alpha[count.index]}.pem"
    ]
    
  }
  
}

resource "null_resource" "start_minion" {
  count = var.node_count
  
  depends_on = [
    null_resource.bootstrap_salt_keys
  ]

  triggers = {
    id = digitalocean_droplet.salt_minion[count.index].id
  }

  connection {
    bastion_host = var.salt_master_public_ip_address
    private_key = var.autogenerated_ssh_private_key
    host = element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)
    user = "root"
    type = "ssh"
    timeout = "5m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "service salt_minion start"
    ]
    
  }

}

resource "digitalocean_record" "salt_minion_public" {
  count = var.node_count
  domain = var.domain_id
  type = "A"
  name = "${var.name}-${var.alpha[count.index]}"
  value = element(digitalocean_droplet.salt_minion.*.ipv4_address, count.index)
}

resource "digitalocean_record" "salt_minion_private" {
  count = var.node_count
  domain = var.domain_id
  type = "A"
  name = "${var.name}-${var.alpha[count.index]}.private"
  value = element(digitalocean_droplet.salt_minion.*.ipv4_address_private, count.index)
}

output "salt_minion_private_ip_addresses" {
  value = digitalocean_droplet.salt_minion.*.ipv4_address_private
}

output "salt_minion_public_ip_addresses" {
  value = digitalocean_droplet.salt_minion.*.ipv4_address
}

output "droplet_ids" {
  value = digitalocean_droplet.salt_minion.*.id
}

output "provision" {
  value = var.provision
}

